# Short login banner with OS and board details. Shown once per interactive
# login; not repeated by `sudo -i` and skipped when ~/.hushlogin exists.

if [ -t 1 ] && [ -z "$SUDO_USER" ] && [ ! -e "$HOME/.hushlogin" ]; then
(
    PATH="$PATH:/usr/sbin:/sbin"
    esc=$(printf '\033')
    d="${esc}[2m" b="${esc}[1m" r="${esc}[0m"

    # Board: stm32mp1-kaonic1s-r24 -> Kaonic 1S r24
    machine=$(cat /etc/kaonic/kaonic_machine 2>/dev/null)
    case "$machine" in
        *kaonic*)
            board=$(echo "${machine#*-}" | sed 's/^kaonic\([0-9]*\)\([a-z]*\)-*/Kaonic \1\2 /' |
                    awk '{ printf "%s %s %s", $1, toupper($2), $3 }')
            ;;
        *)
            board=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null)
            ;;
    esac
    serial=$(cat /etc/kaonic/kaonic_serial 2>/dev/null)

    . /etc/os-release 2>/dev/null
    os="OpenSTLinux ${VERSION_ID%%-*}"
    kernel="$(uname -r | cut -d- -f1) $(uname -m)"

    slot=$(sed -n 's/.*kaonic\.slot=\([a-z]*\).*/\1/p' /proc/cmdline | tr a-z A-Z)
    [ -n "$slot" ] || slot="-"

    up=$(awk '{ s = int($1); d = int(s / 86400); h = int(s % 86400 / 3600); m = int(s % 3600 / 60);
                if (d) printf "%dd %dh %dm", d, h, m; else if (h) printf "%dh %dm", h, m; else printf "%dm", m }' /proc/uptime)
    load=$(cut -d' ' -f1 /proc/loadavg)

    mem=$(awk '/^MemTotal:/ { t = $2 } /^MemAvailable:/ { a = $2 }
               END { printf "%d/%d MB", (t - a) / 1024, t / 1024 }' /proc/meminfo)
    disk=$(df -P / 2>/dev/null | awk 'NR == 2 { printf "%.1f/%.1f GB", $3 / 1048576, $2 / 1048576 }')

    temp=""
    for t in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp1_input; do
        [ -r "$t" ] || continue
        temp="$(( $(cat "$t") / 1000 ))°C"
        break
    done

    # Two interfaces per line so the banner stays within 80 columns.
    net=$(ip -4 -o addr show 2>/dev/null | awk '$2 != "lo" { sub("/.*", "", $4);
            printf "%s%s %s", (n == 0 ? "" : n % 2 ? "  " : "\n"), $2, $4; n++ }')
    [ -n "$net" ] || net="-"

    # Kaonic logo (bar, chevron, radio waves), yellow to orange like the
    # brand gradient, with the details beside it.
    c1="${esc}[38;5;220m" c2="${esc}[38;5;214m" c3="${esc}[38;5;208m"
    l1="${c1}██   ▄█▀ ▄▀▄ ▀▄ ${r}"
    l2="${c1}██ ▄█▀ ▄██  █  █${r}"
    l3="${c2}██ ▀█▄ ▀██  █  █${r}"
    l4="${c3}██   ▀█▄ ▀▄▀ ▄▀ ${r}"
    pad="                "

    k() { printf "${d}%s${r} %s" "$1" "$2"; }

    echo
    echo
    printf "  %s  ${b}%s${r}  ${d}%s${r}\n" "$l1" "${board:-Kaonic}" "$serial"
    printf "  %s  ${d}%s · Linux %s${r}\n" "$l2" "$os" "$kernel"
    printf "  %s  %s  %s  %s%s\n" "$l3" "$(k Up "$up")" "$(k Load "$load")" "$(k Slot "$slot")" "${temp:+  $(k Temp "$temp")}"
    printf "  %s  %s  %s\n" "$l4" "$(k Mem "$mem")" "$(k Disk "$disk")"
    label=Net
    echo "$net" | while IFS= read -r line; do
        printf "  %s  %s\n" "$pad" "$(k "${label:-   }" "$line")"
        label=""
    done
    echo
    printf "  ${d}© @BUILD_YEAR@ Beechat Network Systems Ltd.${r}\n"
    if [ "$(id -u)" -ne 0 ]; then
        case " $(id -nG) " in
            *" sudo "*) printf "  ${d}Use ${r}sudo${d} for administration (sudo -i for a root shell).${r}\n" ;;
            *) printf "  ${d}View-only account: no administrator rights.${r}\n" ;;
        esac
    fi
    echo
)
fi
