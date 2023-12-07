t1 = tasmota.cmd('timer 1')['Timer1']
t2 = tasmota.cmd('timer 2')['Timer1']

t3 = tasmota.cmd('timer 3')['Timer1']
t4 = tasmota.cmd('timer 4')['Timer1']

cur_time = tasmota.time_dump(tasmota.rtc()['local'])

def tasmota_log(string)
    tasmota.log(string)
    print(string)
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
        tasmota.log(string.format("swy: current week day (%u) is an active day", cur_time['weekday']))

        if (((cur_time['hour'] * 60) + cur_time['min']) >=
            ((ht_start['hour'] * 60) + ht_start['min']))
    
            if (((cur_time['hour'] * 60) + cur_time['min']) <=
                ((ht_end  ['hour'] * 60) + ht_end  ['min']))
                tasmota.log(
                    string.format(
                        "swy: current time (%u:%u) is inside the valid interval (from %u:%u to %u:%u)",
                        cur_time['hour'], cur_time['min'],
                        ht_start['hour'], ht_start['min'],
                        ht_end  ['hour'], ht_end  ['min']
                    )
                )
                # swy: inside the working interval; it should be on
                # tasmota.set_power(relay_index, !!1)
                tasmota.log(string.format("[!!] powering ON relay index %u", relay_index))
                return
            end
        end
    end

    # swy: outside the valid interval; shut it down
    #tasmota.set_power(relay_index, !!0)
    tasmota.log(string.format("[!!] powering OFF relay index %u", relay_index))
end

check_timer_interval_between(0, t1, t2);
#check_timer_interval_between(1, t3, t4);


def test()
    tasmota.log("asdf")
    print("test")
end

test()