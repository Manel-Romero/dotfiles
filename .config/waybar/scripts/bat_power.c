#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>

static const char *P_ENERGY = "/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj";
static const char *P_CAP    = "/sys/class/power_supply/BAT0/capacity";
static const char *P_STAT   = "/sys/class/power_supply/BAT0/status";

// Archivos para cálculo de tiempo restante
static const char *P_E_NOW  = "/sys/class/power_supply/BAT0/energy_now";
static const char *P_E_FULL = "/sys/class/power_supply/BAT0/energy_full";
static const char *P_P_NOW  = "/sys/class/power_supply/BAT0/power_now";
static const char *P_C_NOW  = "/sys/class/power_supply/BAT0/charge_now";
static const char *P_C_FULL = "/sys/class/power_supply/BAT0/charge_full";
static const char *P_CURR   = "/sys/class/power_supply/BAT0/current_now";
static const char *P_VOLT   = "/sys/class/power_supply/BAT0/voltage_now";

static volatile sig_atomic_t show_power = 0;

static void handle_sigusr1(int sig) {
    (void)sig;
    show_power = !show_power;
}

static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + ((double)ts.tv_nsec / 1e9);
}

static int read_int(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    int val = 0;
    if (fscanf(f, "%d", &val) != 1) val = -1;
    fclose(f);
    return val;
}

static unsigned long long read_ull(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    unsigned long long val = 0;
    if (fscanf(f, "%llu", &val) != 1) val = 0;
    fclose(f);
    return val;
}

static void read_str(const char *path, char *buf, size_t size) {
    FILE *f = fopen(path, "r");
    if (!f) {
        strncpy(buf, "Unknown", size);
        return;
    }
    if (fgets(buf, size, f)) {
        buf[strcspn(buf, "\r\n")] = 0;
    } else {
        strncpy(buf, "Unknown", size);
    }
    fclose(f);
}

static void get_time_remaining(const char *status, char *out, size_t out_size) {
    double energy_now = (double)read_ull(P_E_NOW);
    double energy_full = (double)read_ull(P_E_FULL);
    double power = (double)read_ull(P_P_NOW);

    // Fallback a charge / current / voltage si el driver usa unidades microamp
    if (energy_now == 0) energy_now = (double)read_ull(P_C_NOW);
    if (energy_full == 0) energy_full = (double)read_ull(P_C_FULL);
    if (power == 0) {
        double curr = (double)read_ull(P_CURR);
        double volt = (double)read_ull(P_VOLT);
        if (curr > 0 && volt > 0) {
            power = (curr * volt) / 1e6;
        } else {
            power = curr;
        }
    }

    if (strncmp(status, "Full", 4) == 0) {
        snprintf(out, out_size, "Batería llena (100%%)");
        return;
    }

    if (power <= 0) {
        snprintf(out, out_size, "Estado: %s", status);
        return;
    }

    int is_charging = (strncmp(status, "Char", 4) == 0);
    double hours = 0.0;

    if (is_charging) {
        if (energy_full > energy_now) {
            hours = (energy_full - energy_now) / power;
        }
    } else {
        hours = energy_now / power;
    }

    int h = (int)hours;
    int m = (int)((hours - h) * 60);

    if (h < 0 || h > 99) {
        snprintf(out, out_size, "Estado: %s (calculando...)", status);
        return;
    }

    if (is_charging) {
        snprintf(out, out_size, "Full in %dh and %dmin", h, m);
    } else {
        snprintf(out, out_size, "Empty in %dh and %dmin", h, m);
    }
}

int main(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_sigusr1;
    sigaction(SIGUSR1, &sa, NULL);

    const char *icons[] = {"", "", "", "", ""};

    unsigned long long last_energy = read_ull(P_ENERGY);
    double last_time = get_time_sec();

    while (1) {
        int cap = read_int(P_CAP);
        char status[32] = {0};
        read_str(P_STAT, status, sizeof(status));

        unsigned long long now_energy = read_ull(P_ENERGY);
        double now_time = get_time_sec();
        double dt = now_time - last_time;
        double watts = (dt > 0 && last_energy > 0) ? ((double)(now_energy - last_energy) / (dt * 1e6)) : 0.0;

        last_energy = now_energy;
        last_time = now_time;

        int icon_idx = cap / 20;
        if (icon_idx > 4) icon_idx = 4;
        if (icon_idx < 0) icon_idx = 0;
        const char *icon = icons[icon_idx];

        const char *css_class = (cap <= 15) ? "critical" : ((cap <= 30) ? "warning" : "");
        int is_charging = (strncmp(status, "Char", 4) == 0);

        char tooltip[64] = {0};
        get_time_remaining(status, tooltip, sizeof(tooltip));

        if (show_power) {
            const char *prefix = is_charging ? "+" : "";
            printf("{\"text\": \"%s%.2fW %d%% %s\", \"class\": \"%s\", \"tooltip\": \"%s\"}\n",
                   prefix, watts, cap, icon, css_class, tooltip);
        } else {
            printf("{\"text\": \"%d%% %s\", \"class\": \"%s\", \"tooltip\": \"%s\"}\n",
                   cap, icon, css_class, tooltip);
        }
        fflush(stdout);

        sleep(2);
    }

    return 0;
}
