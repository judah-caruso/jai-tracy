// This is an example from Thread/examples/thread_group but with profiling.

pool: Pool;
thread_group: Thread_Group;

NUM_WORK_ITEMS :: 10000;

main :: () {
    set_thread_name("main");

    init_thread_group();
    start(*thread_group);
    set_allocators(*pool);  

    {
        zone("Creating summation work items");

        for 1..NUM_WORK_ITEMS {
            work := New(Summation, allocator=pool_allocator, allocator_data=*pool);
            work.input_number = random_get() >> 12;
            if work.input_number == 0  work.input_number = 1;
            add_work(*thread_group, work, tprint("Work item %", it));
        }
    }

    work_remaining := NUM_WORK_ITEMS;

    while work_remaining > 0 {
        sleep_milliseconds(10);

        zone("Getting completed work");
        results := get_completed_work(*thread_group);

        for results {
            summation := cast(*Summation) it;

            n := summation.input_number;
            desired_result := (n * (n + 1)) / 2;

            assert(summation.output_sum == desired_result);

            log("Successful result: Sum(1..%) == %.\n", n, desired_result);
        }

        work_remaining -= results.count;

        reset_temporary_storage();
    }

    shutdown(*thread_group);
    print("Done!\n");
}

Summation :: struct {
    input_number: u64; 
    output_sum:   u64; 
}

init_thread_group :: () {
    zone("Initializing thread group");

    num_cpus := get_number_of_processors();

    assert(num_cpus >= 1);
    if num_cpus > 200  num_cpus = 200;

    #if (OS == .WINDOWS) || (OS == .LINUX) {
        num_cpus /= 2;
    }

    num_threads := max(num_cpus - 1, 2);
    
    log("This machine reports % CPUs; starting % threads.\n", num_cpus, num_threads);
    
    init(*thread_group, num_threads, summation_proc);

    thread_group.name    = "Example";
    thread_group.logging = false;
    
    {
        Dummy_Data :: struct {
            name := "Lord Dimwit Flathead the Excessive";
        }

        dummy_data := New(Dummy_Data);
        
        for * thread_group.worker_info {
            it.thread.data = *dummy_data;
        }
    }
}

summation_proc :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
    zone("Summation");

    summation := cast(*Summation) work;

    result: u64;
    for 1..summation.input_number {
        result += it;
    }

    summation.output_sum = result;

    return .CONTINUE;
}

#load "../module.jai";

#import "Basic";
#import "Pool";
#import "Thread";
#import "System";
#import "Random";
