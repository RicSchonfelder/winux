/*
 * anydesk-tray-icon.so  -  substitui o icone da bandeja do AnyDesk por uma
 * versao minimalista (desenho branco, sem o retangulo vermelho).
 *
 * Como funciona: o AnyDesk cria o icone da bandeja chamando
 * gtk_status_icon_new_from_pixbuf(). Interceptamos essa chamada (LD_PRELOAD)
 * e entregamos o nosso proprio pixbuf. Nada no binario do AnyDesk e alterado.
 *
 * Icone usado: $ANYDESK_TRAY_ICON, por omissao:
 *   ~/Projetos/Programas/anydesk/icone-tray/icons/tray-16.png
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

typedef void GdkPixbuf;
typedef void GtkStatusIcon;

/* so age no proprio AnyDesk: se o LD_PRELOAD for global, os outros programas
 * (que tambem usam gtk_status_icon) ficam intactos. */
static int is_anydesk(void)
{
    char buf[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
    if (n <= 0) return 0;
    buf[n] = 0;
    const char *base = strrchr(buf, '/');
    base = base ? base + 1 : buf;
    return strncmp(base, "anydesk", 7) == 0;
}

static const char *icon_path(void)
{
    static char resolved[PATH_MAX];
    static int done = 0;
    if (done) return resolved[0] ? resolved : NULL;
    done = 1;

    const char *p = getenv("ANYDESK_TRAY_ICON");
    if (p && *p) { strncpy(resolved, p, PATH_MAX - 1); return resolved; }

    const char *home = getenv("HOME");
    if (home && *home) {
        snprintf(resolved, PATH_MAX,
                 "%s/Projetos/Programas/anydesk/icone-tray/icons/tray-16.png", home);
        if (access(resolved, R_OK) == 0) return resolved;
    }
    resolved[0] = 0;
    return NULL;
}

static GdkPixbuf *load_icon(void)
{
    if (!is_anydesk()) return NULL;
    const char *p = icon_path();
    if (!p) return NULL;
    typedef GdkPixbuf *(*new_from_file_t)(const char *, void *);
    new_from_file_t f = (new_from_file_t)dlsym(RTLD_DEFAULT, "gdk_pixbuf_new_from_file");
    if (!f) return NULL;
    return f(p, NULL);
}

GtkStatusIcon *gtk_status_icon_new_from_pixbuf(GdkPixbuf *pb)
{
    static GtkStatusIcon *(*real)(GdkPixbuf *) = NULL;
    if (!real)
        real = (GtkStatusIcon *(*)(GdkPixbuf *))dlsym(RTLD_NEXT,
                                                      "gtk_status_icon_new_from_pixbuf");
    GdkPixbuf *mine = load_icon();
    return real(mine ? mine : pb);
}

void gtk_status_icon_set_from_pixbuf(GtkStatusIcon *si, GdkPixbuf *pb)
{
    static void (*real)(GtkStatusIcon *, GdkPixbuf *) = NULL;
    if (!real)
        real = (void (*)(GtkStatusIcon *, GdkPixbuf *))dlsym(RTLD_NEXT,
                                                             "gtk_status_icon_set_from_pixbuf");
    GdkPixbuf *mine = load_icon();
    real(si, mine ? mine : pb);
}
