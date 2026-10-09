/* wl-copy-types MIME=FILE...: put several representations of one item on the Wayland
 * clipboard at once (wl-copy offers a single MIME type), through ext-data-control.
 *
 * xwayland-satellite hands every offered type to X11 clients, so Wine programs can pick the one
 * they understand (image/bmp becomes CF_DIB). The command returns once the selection is set;
 * a background copy serves the data until another program copies something. */
#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <wayland-client.h>

#include "ext-data-control-v1-client-protocol.h"

#define MAX_ITEMS 8

struct item {
    const char *mime;
    char *data;
    size_t len;
};

static struct item items[MAX_ITEMS];
static int n_items;
static struct wl_seat *seat;
static struct ext_data_control_manager_v1 *manager;
static int cancelled;

static void die(const char *message)
{
    fprintf(stderr, "wl-copy-types: %s\n", message);
    exit(1);
}

static void read_file(struct item *item, const char *path)
{
    FILE *file = fopen(path, "rb");
    size_t capacity = 1 << 20, got;

    if (!file) {
        perror(path);
        exit(1);
    }
    item->data = malloc(capacity);
    item->len = 0;
    while (item->data && (got = fread(item->data + item->len, 1, capacity - item->len, file)) > 0) {
        item->len += got;
        if (item->len == capacity) {
            capacity *= 2;
            item->data = realloc(item->data, capacity);
        }
    }
    fclose(file);
    if (!item->data)
        die("out of memory");
}

static void registry_global(void *data, struct wl_registry *registry, uint32_t name,
                            const char *interface, uint32_t version)
{
    (void)data; (void)version;
    if (!seat && !strcmp(interface, wl_seat_interface.name))
        seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
    else if (!strcmp(interface, ext_data_control_manager_v1_interface.name))
        manager = wl_registry_bind(registry, name, &ext_data_control_manager_v1_interface, 1);
}

static void registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
    (void)data; (void)registry; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    registry_global,
    registry_global_remove,
};

static void source_send(void *data, struct ext_data_control_source_v1 *source,
                        const char *mime, int32_t fd)
{
    (void)data; (void)source;
    for (int i = 0; i < n_items; i++) {
        if (strcmp(items[i].mime, mime))
            continue;
        for (size_t done = 0; done < items[i].len;) {
            ssize_t wrote = write(fd, items[i].data + done, items[i].len - done);
            if (wrote < 0 && errno == EINTR)
                continue;
            if (wrote <= 0)
                break;
            done += (size_t)wrote;
        }
        break;
    }
    close(fd);
}

static void source_cancelled(void *data, struct ext_data_control_source_v1 *source)
{
    (void)data; (void)source;
    cancelled = 1;
}

static const struct ext_data_control_source_v1_listener source_listener = {
    source_send,
    source_cancelled,
};

static void device_data_offer(void *data, struct ext_data_control_device_v1 *device,
                              struct ext_data_control_offer_v1 *offer)
{
    (void)data; (void)device; (void)offer;
}

static void device_selection(void *data, struct ext_data_control_device_v1 *device,
                             struct ext_data_control_offer_v1 *offer)
{
    (void)data; (void)device;
    if (offer)
        ext_data_control_offer_v1_destroy(offer);
}

static void device_finished(void *data, struct ext_data_control_device_v1 *device)
{
    (void)data; (void)device;
    cancelled = 1;
}

static void device_primary_selection(void *data, struct ext_data_control_device_v1 *device,
                                     struct ext_data_control_offer_v1 *offer)
{
    (void)data; (void)device;
    if (offer)
        ext_data_control_offer_v1_destroy(offer);
}

static const struct ext_data_control_device_v1_listener device_listener = {
    device_data_offer,
    device_selection,
    device_finished,
    device_primary_selection,
};

int main(int argc, char **argv)
{
    struct wl_display *display;
    struct wl_registry *registry;
    struct ext_data_control_source_v1 *source;
    struct ext_data_control_device_v1 *device;
    int devnull;

    if (argc < 2 || argc - 1 > MAX_ITEMS) {
        fprintf(stderr, "usage: wl-copy-types MIME=FILE...\n");
        return 2;
    }
    for (int i = 1; i < argc; i++) {
        char *separator = strchr(argv[i], '=');
        if (!separator)
            die("arguments are MIME=FILE");
        *separator = '\0';
        items[n_items].mime = argv[i];
        read_file(&items[n_items], separator + 1);
        n_items++;
    }
    signal(SIGPIPE, SIG_IGN);

    display = wl_display_connect(NULL);
    if (!display)
        die("cannot connect to the Wayland display");
    registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);
    if (!seat || !manager)
        die("the compositor does not offer ext-data-control");

    source = ext_data_control_manager_v1_create_data_source(manager);
    ext_data_control_source_v1_add_listener(source, &source_listener, NULL);
    for (int i = 0; i < n_items; i++)
        ext_data_control_source_v1_offer(source, items[i].mime);
    device = ext_data_control_manager_v1_get_data_device(manager, seat);
    ext_data_control_device_v1_add_listener(device, &device_listener, NULL);
    ext_data_control_device_v1_set_selection(device, source);
    wl_display_roundtrip(display);
    if (cancelled)
        die("the compositor refused the selection");

    /* The selection is ours: keep serving it from a background copy. _exit, so the parent
     * does not tear down the connection the child uses. */
    if (fork())
        _exit(0);
    setsid();
    devnull = open("/dev/null", O_RDWR);
    for (int fd = 0; fd <= 2; fd++)
        dup2(devnull, fd);
    while (!cancelled && wl_display_dispatch(display) != -1)
        ;
    return 0;
}
