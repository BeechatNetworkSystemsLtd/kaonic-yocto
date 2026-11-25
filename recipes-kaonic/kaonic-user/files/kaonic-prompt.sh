# Coloured prompt for bash and busybox ash: user@host in red for root, yellow
# for administrators (sudo group), green for view-only users; the working
# directory in blue.

if [ -n "$PS1" ]; then
    _esc=$(printf '\033')
    if [ "$(id -u)" -eq 0 ]; then
        _user_color='1;31'
    else
        case " $(id -nG) " in
            *" sudo "*) _user_color='1;33' ;;
            *) _user_color='1;32' ;;
        esac
    fi
    PS1="\[${_esc}[${_user_color}m\]\u@\h\[${_esc}[0m\]:\[${_esc}[1;34m\]\w\[${_esc}[0m\]\\$ "
    unset _esc _user_color
fi

# /etc/profile adds the sbin directories only for root; the admin user administers
# the system through sudo and needs them too.
case ":$PATH:" in
    *:/usr/sbin:*) ;;
    *) PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin" ;;
esac
