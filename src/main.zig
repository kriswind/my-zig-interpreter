const std = @import("std");

const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literal: ?[]u8,
};

fn addToken(tokenType: TokenType, lexeme: u8, literal: ?[]u8) Token {
    return Token{ .type = tokenType, .lexeme = &[_]u8{lexeme}, .literal = literal };
}

fn scanToken(i: u8) Token {
    switch (i) {
        '(' => {
            return addToken(.LEFT_PAREN, i, null);
        },
        ')' => {
            return addToken(.RIGHT_PAREN, i, null);
        },
        0 => {
            return addToken(.EOF, i, null);
        },
        else => {
            return addToken(.IDENTIFIER, i, null); // Default to IDENTIFIER for now
        },
    }
}

fn printToken(i: u8) !void {
    const token: Token = scanToken(i);
    try std.io.getStdOut().writer().print("{any} {any} {any}\n", .{ token.type, token.lexeme, token.literal });
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    if (file_contents.len > 0) {
        for (file_contents) |i| {
            if (i == '\n') {
                continue;
            }
            try printToken(i);
        }
    } else {}
}
