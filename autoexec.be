t1 = tasmota.cmd('timer 1')['Timer1']
t2 = tasmota.cmd('timer 2')['Timer1']

t3 = tasmota.cmd('timer 3')['Timer1']
t4 = tasmota.cmd('timer 4')['Timer1']

cur_time = tasmota.time_dump(tasmota.rtc()['local'])

check_timer_interval_between(0, t1, t2);
#check_timer_interval_between(1, t3, t4);

def


def check_timer_interval_between(relay_index, timer_start, timer_end)
    timer_start = string.split(timer_start['Time'], ":")
    timer_end   = string.split(timer_end  ['Time'], ":")

    ht_start = {'hour': number(timer_start[0]), 'min': number(timer_start[1])}
    ht_end   = {'hour': number(timer_end  [0]), 'min': number(timer_end  [1])}

    # swy: e.g. only sunday is '1000000', monday is '0100000' and thursday is '0000100'
    #           all the days of the week is defined as the stringfied bitfield '1111111'
    #           while the Berry 'weekday' format starts on monday with index 0.
    if (timer_start['Days'][cur_time['weekday'] % 6] != '1' ||
          timer_end['Days'][cur_time['weekday'] % 6] != '1')
        tasmota.log("swy: current week day is not an active day; powering it off")

        # swy: shut it down
        tasmota.set_power(relay_index, !!0)
        return
    end

    
    if ((cur_time['hour'] * 60) + cur_time['hour'] <
        (ht_start['hour'] * 60) + ht_start['min' ])

        # swy: shut it down
        tasmota.set_power(relay_index, !!0)
        return
    end

    if ((cur_time['hour'] * 60) + cur_time['hour'] >
        (ht_end  ['hour'] * 60) + ht_end  ['min' ])

        # swy: shut it down
        tasmota.set_power(relay_index, !!0)
        return
    end

    # swy: shut it down
    tasmota.set_power(relay_index, !!1)
end