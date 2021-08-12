ZoneCtx            :: ___tracy_c_zone_context;
SourceLocationData :: ___tracy_source_location_data;

zone :: (name := "Unnamed Scope", color := 0, loc := #caller_location) #expand {
    ctx := zone_begin(loc);

    ___tracy_emit_zone_name(ctx, name.data, name.count);
    if color != 0 ___tracy_emit_zone_color(ctx, color);

    `defer zone_end(ctx);
}

zone_begin :: (loc := #caller_location) -> ZoneCtx #expand {
    // __tracy_init_thread();
    // c_proc_name := temp_c_string(get_name_of_current_proc());

    proc_name := get_name_of_current_proc();

    id := ___tracy_alloc_srcloc(
        xx loc.line_number,
        loc.fully_pathed_filename.data,
        xx loc.fully_pathed_filename.count,
        proc_name.data,
        xx proc_name.count,
    );

    return ___tracy_emit_zone_begin_alloc_callstack(id, 2, 1);
}

zone_end :: (ctx: ZoneCtx) #expand {
    ___tracy_emit_zone_end(ctx);
}

zone_text :: (ctx: ZoneCtx, text: string) #expand {
    ___tracy_emit_zone_text(ctx, text.data, xx text.count);
}

frame_mark_start :: (name: string) #expand {
    ___tracy_emit_frame_mark_start(temp_c_string(name));
}

frame_mark_end :: (name: string) #expand {
    ___tracy_emit_frame_mark_end(temp_c_string(name));
}

frame_mark :: (name := "") #expand {
    if name.count <= 0 {
        ___tracy_emit_frame_mark(null);
    } else {
        ___tracy_emit_frame_mark(temp_c_string(name));
    }
}

set_thread_name :: (name: string) #expand {
    ___tracy_set_thread_name(temp_c_string(name));
}

#scope_file

get_name_of_current_proc :: () -> string #expand {
    return () -> string {
        if !context.stack_trace {
            return "procedure (stack trace disabled)";
        }
        else {
            return context.stack_trace.info.name;
        }
    }();
}
