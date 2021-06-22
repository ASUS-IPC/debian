#!/bin/bash
#This is the factory test tool for pv100a with rt5616 codec.

REC_FILENAME=record.wav
DAC_VOLUME=175

function audio_test_usage() {
    cat <<USAGE_MESSAGE
usage: ./AudioTest.sh [OPTION] ...
    OPTION:
        0 - playback [SINK] [FILE] [VOLUME(optional)]
        1 - record [RECORD_TIME]
        2 - record_and_playback [SINK] [RECORD_TIME]
        3 - playback on repeat [SINK] [FILE]
        4 - audio loopback test
    SINK:
        0 - HDMI audio output
        1 - Line out via High-Density Connector
    FILE:
        Select a file you want play
    RECORD_TIME:
        Recording time in seconds
    VOLUME:
        DAC Volume control, it is optional.
        Range: 0~175 (default is 175)
USAGE_MESSAGE
}

function dapm_widgets_hpo() {
    amixer -c$rt5616_card_num cset name="DAC MIXL INF1 Switch" 1
    amixer -c$rt5616_card_num cset name="DAC MIXR INF1 Switch" 1
    amixer -c$rt5616_card_num cset name="Stereo DAC MIXL DAC L1 Switch" 1
    amixer -c$rt5616_card_num cset name="Stereo DAC MIXL DAC R1 Switch" 1
    amixer -c$rt5616_card_num cset name="HPO MIX DAC1 Switch" 1
    amixer -c$rt5616_card_num cset name="HP Playback Switch" 1 1
    amixer -c$rt5616_card_num cset name="DAC1 Playback Volume" $DAC_VOLUME $DAC_VOLUME
}

function clear_hpo_mixers() {
    #echo "clear hpo mixers"
    #amixer -c$rt5616_card_num cset name="DAC MIXL INF1 Switch" 0
    #amixer -c$rt5616_card_num cset name="DAC MIXR INF1 Switch" 0
    #amixer -c$rt5616_card_num cset name="Stereo DAC MIXL DAC L1 Switch" 0
    #amixer -c$rt5616_card_num cset name="Stereo DAC MIXL DAC R1 Switch" 0
    #amixer -c$rt5616_card_num cset name="HPO MIX DAC1 Switch" 0
    #amixer -c$rt5616_card_num cset name="HP Playback Switch" 0 0
    amixer -c$rt5616_card_num cset name="DAC1 Playback Volume" 175 175
}

function dapm_widgets_mic() {
    amixer -c$rt5616_card_num cset name="RECMIXL BST1 Switch" 1
    amixer -c$rt5616_card_num cset name="RECMIXR BST1 Switch" 1
    amixer -c$rt5616_card_num cset name="Stereo1 ADC MIXL ADC1 Switch" 1
    amixer -c$rt5616_card_num cset name="Stereo1 ADC MIXR ADC1 Switch" 1
    amixer -c$rt5616_card_num cset name="ADC Capture Switch" 1 1
}

function clear_mic_mixers() {
    #echo "clear mic mixers"
    amixer -c$rt5616_card_num cset name="RECMIXL BST1 Switch" 0
    amixer -c$rt5616_card_num cset name="RECMIXR BST1 Switch" 0
    amixer -c$rt5616_card_num cset name="Stereo1 ADC MIXL ADC1 Switch" 0
    amixer -c$rt5616_card_num cset name="Stereo1 ADC MIXR ADC1 Switch" 0
    amixer -c$rt5616_card_num cset name="ADC Capture Switch" 0 0
}

function audio_test_record() {
    if [ "$#" -lt 1 ]
    then
        echo "audio_test_record(): Too few arguments!!" >&2
        audio_test_usage;
        return 1;
    fi

    REC_TIME="$1"
    dapm_widgets_mic;
    arecord -Dplughw:$rt5616_card_num -f S16_LE -r 48000 -c 1 -d $REC_TIME $REC_FILENAME
    if [[ $? -ne 0 ]]
    then
        clear_mic_mixers;
        return 1
    fi

    clear_mic_mixers;
    return $?
}

function audio_test_playback() {
    if [ "$#" -eq 3 ]
    then
        if [ $3 -ge 0 -a $3 -le 175 ] && [[ $3 == ?(-)+([0-9]) ]]
        then
            echo "audio_test_playback(): Adjust Volume to $3 !" >&2
            DAC_VOLUME="$3"
        else
            echo "audio_test_playback(): Volume shoud be 0 to 175 !" >&2
            audio_test_usage;
            return 1;
        fi
    fi

    DEVICE="$1"
    FILENAME="$2"
    case "$DEVICE" in
        '0') # HDMI Output
            aplay -Dplughw:$hdmi_card_num $FILENAME
            if [[ $? -ne 0 ]]
            then
                return 1
            fi
            return $?
            ;;
        '1') # Line Out
            dapm_widgets_hpo;
            aplay -Dplughw:$rt5616_card_num $FILENAME
            if [[ $? -ne 0 ]]
            then
                clear_hpo_mixers;
                return 1
            fi
            clear_hpo_mixers;
            return $?
            ;;
        *)
            echo "Unknown sink '$DEVICE'" >&2
            audio_test_usage;
            return 1;
            ;;
    esac
}

function audio_test_playback_repeat() {
    if [ "$#" -eq 3 ]
    then
        if [ $3 -ge 0 -a $3 -le 175 ] && [[ $3 == ?(-)+([0-9]) ]]
        then
            echo "audio_test_playback(): Adjust Volume to $3 !" >&2
            DAC_VOLUME="$3"
        else
            echo "audio_test_playback(): Volume shoud be 0 to 175 !" >&2
            audio_test_usage;
            return 1;
        fi
    fi

    DEVICE="$1"
    FILENAME="$2"
    case "$DEVICE" in
        '0') # HDMI Output
            while [ $? -eq 0 ] ; do
                aplay -Dplughw:$hdmi_card_num $FILENAME
            done
            if [[ $? -ne 0 ]]
            then
                return 1
            fi
            return $?
            ;;
        '1') # Line Out
            dapm_widgets_hpo;
            while [ $? -eq 0 ] ; do
                aplay -Dplughw:$rt5616_card_num $FILENAME
            done
            if [[ $? -ne 0 ]]
            then
                clear_hpo_mixers;
                return 1
            fi
            clear_hpo_mixers;
            return $?
            ;;
        *)
            echo "Unknown sink '$DEVICE'" >&2
            audio_test_usage;
            return 1;
            ;;
    esac
}

function audio_test_loopback() {
    echo "Start audio loopback ..."
    dapm_widgets_mic;
    dapm_widgets_hpo;
    while [ $? -eq 0 ] ; do
        arecord -Dplughw:$rt5616_card_num -f S16_LE -r 48000 -c 1 | aplay -Dplughw:$rt5616_card_num -f S16_LE -r 48000 -c 1
    done
    if [[ $? -ne 0 ]]
    then
        clear_mic_mixers;
        clear_hpo_mixers;
        return 1
    fi

    clear_mic_mixers;
    clear_hpo_mixers;
    return $?
}

function audio_test_rec_n_play() {
    if [ "$#" -lt 2 ]
    then
        echo "Too few arguments!!" >&2
        audio_test_usage;
        return 1;
    fi

    REC_TIME="$2"
    dapm_widgets_mic;
    arecord -Dplughw:$rt5616_card_num -f S16_LE -r 48000 -c 1 -d $REC_TIME $REC_FILENAME
    if [[ $? -ne 0 ]]
    then
        clear_mic_mixers;
        return 1
    fi

    clear_mic_mixers;
    audio_test_playback "$1" "$REC_FILENAME" || return 1
}

function audio_test_main() {
    echo ""
    echo "audio_test : "

    if [ $# -le 0 ]
    then
        echo "audio_test_main(): Too few arguments!!" >&2
        audio_test_usage;
        return 1
    fi

    echo ==================== "Current Sound Card(s)" ====================
    cat /proc/asound/cards
    echo ===============================================================
    out=$(cat /proc/asound/cards | grep imxaudiohdmi)
    hdmi_card_num=$(echo $out | cut -d" " -f 1)
    echo "imxaudiohdmi, card number = "$hdmi_card_num
    out=$(cat /proc/asound/cards | grep sndpv100acard)
    rt5616_card_num=$(echo $out | cut -d" " -f 1)
    echo "sndpv100acard, card number = "$rt5616_card_num

    ACTION="$1"
    shift

    case "$ACTION" in
        '0') # Playback
            audio_test_playback "$@" || return 1
            ;;
        '1') # Record
            audio_test_record "$@" || return 1
            ;;
        '2') # Record & Playback
            audio_test_rec_n_play "$@" || return 1
            ;;
        '3') # Playback on repeat
            audio_test_playback_repeat "$@" || return 1
            ;;
        '4') # Audio loopback
            audio_test_loopback "$@" || return 1
            ;;
        *)
            audio_test_usage;
            return 1
            ;;
    esac
}

audio_test_main "$@"
if [[ $? -eq 0 ]]
then
    echo "PASS";
else
    echo "FAIL";
fi
