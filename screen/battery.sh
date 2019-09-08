# LICENSE This code is not under the same license as the rest of the project as it's "stolen". It's cloned from https://github.com/richoH/dotfiles/blob/master/bin/battery and just some modifications are done so it works for my laptop. Check that URL for more recent versions.

TMUX_POWERLINE_SEG_BATTERY_TYPE_DEFAULT="percentage"
TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS_DEFAULT=5

HEART_FULL="♥"
HEART_EMPTY="♡"

ostype() { echo $OSTYPE | tr '[A-Z]' '[a-z]'; }

SHELL_PLATFORM='unknown'

case "$(ostype)" in
	*'linux'*	) SHELL_PLATFORM='linux'	;;
	*'darwin'*	) SHELL_PLATFORM='osx'		;;
	*'bsd'*		) SHELL_PLATFORM='bsd'		;;
esac

shell_is_linux() { [[ $SHELL_PLATFORM == 'linux' || $SHELL_PLATFORM == 'bsd' ]]; }
shell_is_osx()   { [[ $SHELL_PLATFORM == 'osx' ]]; }
shell_is_bsd()   { [[ $SHELL_PLATFORM == 'bsd' || $SHELL_PLATFORM == 'osx' ]]; }

run_segment() {
	__process_settings
	if shell_is_osx; then
		battery_status=$(__battery_osx)
	else
		battery_status=$(__battery_linux)
	fi
	#[ -z "$battery_status" ] && return

	case "$TMUX_POWERLINE_SEG_BATTERY_TYPE" in
		"percentage")
			output="${HEART_FULL} ${battery_status}%"
			;;
		"cute")
			output=$(__cutinate $battery_status)
	esac
    printf "%s" "$output"
}

__process_settings() {
	if [ -z "$TMUX_POWERLINE_SEG_BATTERY_TYPE" ]; then
		export TMUX_POWERLINE_SEG_BATTERY_TYPE="${TMUX_POWERLINE_SEG_BATTERY_TYPE_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS" ]; then
		export TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS="${TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS_DEFAULT}"
	fi
}

__battery_osx() {
	ioreg -c AppleSmartBattery -w0 | \
		grep -o '"[^"]*" = [^ ]*' | \
		sed -e 's/= //g' -e 's/"//g' | \
		sort | \
		while read key value; do
			case $key in
				"MaxCapacity")
					export maxcap=$value;;
				"CurrentCapacity")
					export curcap=$value;;
				"ExternalConnected")
					export extconnect=$value;;
        "FullyCharged")
          export fully_charged=$value;;
			esac
			if [[ -n $maxcap && -n $curcap && -n $extconnect ]]; then
				if [[ "$curcap" == "$maxcap" || "$fully_charged" == "Yes" && $extconnect == "Yes"  ]]; then
					return
				fi
				charge=`pmset -g batt | grep -o "[0-9][0-9]*\%" | rev | cut -c 2- | rev`
					echo "$charge"
				break
			fi
		done
	}

	__battery_linux() {
		case "$SHELL_PLATFORM" in
			"linux")
				BATPATH=/sys/class/power_supply/BAT0
				if [ ! -d $BATPATH ]; then
					BATPATH=/sys/class/power_supply/BAT1
				fi
				STATUS=$BATPATH/status
				BAT_FULL=$BATPATH/charge_full
				if [ ! -r $BAT_FULL ]; then
					BAT_FULL=$BATPATH/energy_full
				fi
				BAT_NOW=$BATPATH/charge_now
				if [ ! -r $BAT_NOW ]; then
					BAT_NOW=$BATPATH/energy_now
				fi

				if [ "$1" = `cat $STATUS` -o "$1" = "" ]; then
					__linux_get_bat
				fi
				;;
			"bsd")
				STATUS=`sysctl -n hw.acpi.battery.state`
				case $1 in
					"Discharging")
						if [ $STATUS -eq 1 ]; then
							__freebsd_get_bat
						fi
						;;
					"Charging")
						if [ $STATUS -eq 2 ]; then
							__freebsd_get_bat
						fi
						;;
					"")
						__freebsd_get_bat
						;;
				esac
				;;
		esac
	}

	__cutinate() {
		perc=$1
		inc=$(( 100 / $TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS ))

		for i in `seq $TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS`; do
			if [ $perc -lt 99 ]; then
				printf $HEART_EMPTY
			else
				printf $HEART_FULL
			fi
			printf " "
			perc=$(( $perc + $inc ))
		done
	}

	__linux_get_bat() {
		bf=$(cat $BAT_FULL)
		bn=$(cat $BAT_NOW)
		if [ $bn -gt $bf ]; then
			bn=$bf
		fi
		echo $(( 100 * $bn / $bf ))
	}

	__freebsd_get_bat() {
		echo "$(sysctl -n hw.acpi.battery.life)"

	}

run_segment
