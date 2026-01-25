package main

import "core:os"
import "core:mem"
import "core:fmt"

// This is the ONLY definition of Save_Data. 
// Ensure it is deleted from main.odin and types.odin.
Save_Data :: struct #align(8) {
    aurum:           f64,
    ore_counts:      [Ore_Type]f64, 
    miner_counts:    [6]i32,
    factory_counts:  [6]i32,
    upgrades_bought: [3]bool,
}

save_game :: proc(aurum: f64, ores: [Ore_Type]Ore, miners: [6]Upgrade, factories: [6]Upgrade, upgrades: [3]Global_Upgrade) {
    data: Save_Data
    data.aurum = aurum
    
    data.ore_counts[.IRON]     = ores[.IRON].count
    data.ore_counts[.IRON_BAR] = ores[.IRON_BAR].count
    data.ore_counts[.GOLD]     = ores[.GOLD].count
    data.ore_counts[.CRYSTAL]  = ores[.CRYSTAL].count

    for i in 0..<6 {
        data.miner_counts[i]   = i32(miners[i].count)
        data.factory_counts[i] = i32(factories[i].count)
    }
    for i in 0..<3 { data.upgrades_bought[i] = upgrades[i].bought }

    save_size := size_of(Save_Data)
    buffer := make([]byte, save_size) 
    defer delete(buffer) 

    mem.copy(raw_data(buffer), &data, save_size)
    
    path := "save.flsh"

    if success := os.write_entire_file(path, buffer); !success {
        fmt.printf("FAILED TO WRITE: Error 1784 usually means a permissions or alignment issue.\n")
    } else {
        fmt.println("--- SUCCESS: save.flsh written safely ---")
    }
}

load_game :: proc() -> (Save_Data, bool) {
    path := "save.flsh"
    
    if !os.exists(path) {
        return {}, false
    }

    data, ok := os.read_entire_file(path)
    if !ok || len(data) == 0 {
        fmt.println("Save file empty or unreadable.")
        return {}, false
    }

    if len(data) != size_of(Save_Data) {
        fmt.printf("Size Mismatch! File: %v, Expected: %v. Deleting corrupted file.\n", len(data), size_of(Save_Data))
        os.remove(path)
        return {}, false
    }

    save_ptr := cast(^Save_Data)raw_data(data)
    fmt.println("--- LOADED: save.flsh is healthy ---")
    return save_ptr^, true
}