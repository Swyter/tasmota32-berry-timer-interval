import string

# created by swyter in december 2023
# --
# A tiny start-up Berry script for Tasmota32 that tries to convert a pair of two one-shot web UI timers
# into a single interval/activation range. Useful for safely turning off a relay/output when power
# comes back after a brownout and one of the triggers did not fire. 

# swy: log both to the persistent tasmota log (which does not output anything on the
#      berry console when called within functions) as well as the berry console
def tasmota_log(string)
    tasmota.log(string)
    #print(string)
end

tasmota_log("swy: [>>] starting up the interval timer activation script...")

def tasmota_set_power(relay_index_first_is_zero, state)
    var state_string = state ? 'ON' : 'OFF'
    if (tasmota.get_power(relay_index_first_is_zero) != state)
        tasmota_log(string.format("swy: [!!] powering %s (%u) relay index %u", state_string, state, relay_index_first_is_zero))
        # swy: NOTE: this is what actually turns the physical outputs on (true)
        #            or off (false), comment out for stubbing/testing
        tasmota.set_power(relay_index_first_is_zero, state)
    else
        tasmota_log(string.format("swy: [!!] relay index %u is already %s (%u); nothing to do", relay_index_first_is_zero, state_string, state))
    end
end

# swy: keep in mind that for all the legacy tasmota commands everything starts at index one, where as for
#       the berry stuff the first index is always zero, so we need to convert between them; good job!
def check_timer_interval_between(relay_timer_output_number_first_is_one, timer_start, timer_end)
    # swy: make sure our time is up to date; if launching straight from the autoexec.be main
    #      context it may be too early, and we'd get 00:00 and garbage logic
    var cur_time = tasmota.time_dump(tasmota.rtc()['local'])

    # swy: check and ignore inactive timers; as well as a whole host of
    #      fail-safe sanity checks before doing anything
    if (timer_start['Enable'] != 1 ||
        timer_end  ['Enable'] != 1)
        tasmota_log("swy: some of the timers in the interval seem to be disabled; bailing out")
        return
    end

    if (timer_start['Output'] != timer_end['Output'])
        tasmota_log("swy: the timer pair must control the same relay; bailing out")
        return
    end

    if (timer_start['Output'] != relay_timer_output_number_first_is_one)
        tasmota_log(
            string.format(
                "swy: the relay the timer pair controls (%u) must match the one provided as the first parameter (%u); bailing out",
                timer_start['Output'], relay_timer_output_number_first_is_one
            )
        )
        return
    end

    # swy: make sure the mode is set to 'Time' (0), instead of 'Sunrise' (1) or 'Sunset' (2); as those don't use a fixed timestamp
    if (timer_start['Mode'  ] != 0 || timer_end['Mode'  ] != 0)
        tasmota_log("swy: the timer pair must not be in sunrise/sunset mode; bailing out")
        return
    end

    # swy: make sure there's no trigger-time randomization; which we can't handle right now
    if (timer_start['Window'] != 0 || timer_end['Window'] != 0)
        tasmota_log("swy: the timer pair must set the randomized trigger offset to +/- 0")
        return
    end

    # swy: make sure that the first timer is set to On (1) and the second to Off (0),
    #      instead of stuff we don't understand here, like Toggle (2) or Rule (3).
    if (timer_start['Action'] != 1 || timer_end['Action'] != 0)
        tasmota_log("swy: make sure that the first timer is set to ON and the second to OFF; bailing out")
        return
    end

    # --

    # swy: convert the provided e.g. '07:00' string into two 7 and 0 numbers:
    var timer_start_num = string.split(timer_start['Time'], ":")
    var timer_end_num   = string.split(timer_end  ['Time'], ":")

    # swy: make sure we actually have the right time format
    if (timer_start_num.size() != 2 || timer_end_num.size() != 2)
        tasmota_log("swy: the returned timestamps don't seem to contain a HH:MM string; bailing out")
        return
    end

    var ht_start = {'hour': number(timer_start_num[0]), 'min': number(timer_start_num[1])}
    var ht_end   = {'hour': number(timer_end_num  [0]), 'min': number(timer_end_num  [1])}

    # swy: e.g. only sunday is '1000000', monday is '0100000' and thursday is '0000100'
    #           all the days of the week is defined as the stringfied bitfield '1111111'
    #           while the Berry 'weekday' format starts on monday with index 0.
    if (timer_start['Days'][cur_time['weekday'] % 6] == '1' &&
          timer_end['Days'][cur_time['weekday'] % 6] == '1')
          tasmota_log(string.format("swy: current week day (%u) is an active day", cur_time['weekday']))

        if (((ht_start['hour'] * 60) + ht_start['min']) >=
            ((ht_end  ['hour'] * 60) + ht_end  ['min']))
            tasmota_log("swy: the start timer must trigger earlier than the end timer; bailing out")
            return
        end

        if (((cur_time['hour'] * 60) + cur_time['min']) >= # swy: convert to minutes for an easier comparison
            ((ht_start['hour'] * 60) + ht_start['min']))
    
            if (((cur_time['hour'] * 60) + cur_time['min']) <= # swy: same
                ((ht_end  ['hour'] * 60) + ht_end  ['min']))
                tasmota_log(
                    string.format(
                        "swy: current time (%02u:%02u) is inside the valid interval (from %02u:%02u to %02u:%02u)",
                        cur_time['hour'], cur_time['min'],
                        ht_start['hour'], ht_start['min'],
                        ht_end  ['hour'], ht_end  ['min']
                    )
                )
                # swy: we're inside the working interval; it should be on
                tasmota_set_power((relay_timer_output_number_first_is_one - 1), true)
                return
            end
        end

        tasmota_log(
            string.format("swy: current time (%02u:%02u) seems to fall OUTSIDE the valid interval (from %02u:%02u to %02u:%02u)",
                cur_time['hour'], cur_time['min'],
                ht_start['hour'], ht_start['min'],
                ht_end  ['hour'], ht_end  ['min']
            )
        )
    else
        tasmota_log(string.format("swy: current week day (%u) doesn't seem to be an active day; trying to shut down", cur_time['weekday']))
    end

    # swy: outside the valid interval; shut it down
    tasmota_set_power((relay_timer_output_number_first_is_one - 1), false)
end


def schedule_check()
    var t1 = tasmota.cmd('timer1')['Timer1']
    var t2 = tasmota.cmd('timer2')['Timer2']

    var t3 = tasmota.cmd('timer3')['Timer3']
    var t4 = tasmota.cmd('timer4')['Timer4']

    tasmota_log("swy: [**] checking interval timers...")

    # swy: set which timers check which relay output
    check_timer_interval_between(2, t1, t2);
    #check_timer_interval_between(1, t3, t4);
    #check_timer_interval_between(3, t5, t6);
end

# swy: wait ~10 seconds from device startup before checking, for Tasmota to get the current NTP time loaded (otherwise we'd get 00:00)
tasmota.set_timer(10 * 1000, schedule_check)
# swy: plus, add a recurrent task to check every X minutes
tasmota.add_cron("10 */15 * * * *", schedule_check, "every_15_min")