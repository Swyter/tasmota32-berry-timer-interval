t1 = tasmota.cmd('timer1')['Timer1']
t2 = tasmota.cmd('timer2')['Timer2']

t3 = tasmota.cmd('timer3')['Timer3']
t4 = tasmota.cmd('timer4')['Timer4']

cur_time = tasmota.time_dump(tasmota.rtc()['local'])

# swy: log both to the persistent tasmota log (which does not output anything on the
#      berry console when called within functions) as well as the berry console
def tasmota_log(string)
    tasmota.log(string)
    print(string)
end

def tasmota_set_power(relay_index, state)
    var state_string = state ? 'ON' : 'OFF'
    if (tasmota.get_power(relay_index) != state)
        tasmota_log(string.format("swy: [!!] powering %s (%u) relay index %u", state_string, state, relay_index))
        #tasmota.set_power(relay_index, !!0)
    else
        tasmota_log(string.format("swy: [!!] relay index %u is already %s (%u)", relay_index, state_string, state))
    end
end

def check_timer_interval_between(relay_index, timer_start, timer_end)
    tasmota.log("asdf")
    var timer_start_num = string.split(timer_start['Time'], ":")
    var timer_end_num   = string.split(timer_end  ['Time'], ":")

    var ht_start = {'hour': number(timer_start_num[0]), 'min': number(timer_start_num[1])}
    var ht_end   = {'hour': number(timer_end_num  [0]), 'min': number(timer_end_num  [1])}

    # swy: e.g. only sunday is '1000000', monday is '0100000' and thursday is '0000100'
    #           all the days of the week is defined as the stringfied bitfield '1111111'
    #           while the Berry 'weekday' format starts on monday with index 0.
    if (timer_start['Days'][cur_time['weekday'] % 6] == '1' &&
          timer_end['Days'][cur_time['weekday'] % 6] == '1')
          tasmota_log(string.format("swy: current week day (%u) is an active day", cur_time['weekday']))

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
                tasmota_set_power(relay_index, true)
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
        tasmota_log(string.format("swy: current week day (%u) doesn't seem to be an active day", cur_time['weekday']))
    end

    # swy: outside the valid interval; shut it down
    tasmota_set_power(relay_index, false)
end

check_timer_interval_between(1, t1, t2);
#check_timer_interval_between(2, t3, t4);