const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var child = std.process.Child.init(&[_][]const u8{ "sysctl", "-n", "kern.hostname" }, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(stdout);

    const stderr = try child.stderr.?.reader().readAllAlloc(allocator, 1024);
    defer allocator.free(stderr);

    const term = try child.wait();

    switch (term) {
        .Exited => |code| {
            if (code == 0) {
                // Trim any trailing newline
                const hostname = std.mem.trimRight(u8, stdout, "\n");
                try std.io.getStdOut().writer().print("{s}\n", .{hostname});
            } else {
                std.debug.print("Process exited with code {}\n", .{code});
                if (stderr.len > 0) {
                    std.debug.print("{s}\n", .{stderr});
                }
            }
        },
        else => {
            std.debug.print("Process terminated abnormally\n", .{});
        },
    }
}
