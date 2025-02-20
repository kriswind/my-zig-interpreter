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

fn addToken(tokenType: TokenType, lexeme: []const u8, literal: ?[]u8) Token {
    return Token{ .type = tokenType, .lexeme = lexeme, .literal = literal };
}

fn scanToken(i: u8) !Token {
    switch (i) {
        '(' => {
            return addToken(.LEFT_PAREN, "(", null);
        },
        ')' => {
            return addToken(.RIGHT_PAREN, ")", null);
        },
        '{' => {
            return addToken(.LEFT_BRACE, "{", null);
        },
        '}' => {
            return addToken(.RIGHT_BRACE, "}", null);
        },
        '*' => {
            return addToken(.STAR, "*", null);
        },
        '.' => {
            return addToken(.DOT, ".", null);
        },
        ',' => {
            return addToken(.COMMA, ",", null);
        },
        '+' => {
            return addToken(.PLUS, "+", null);
        },
        '-' => {
            return addToken(.MINUS, "-", null);
        },
        ';' => {
            return addToken(.SEMICOLON, ";", null);
        },
        0 => {
            return addToken(.EOF, "", null);
        },
        else => {
            return error.InvalidCharacter;
        },
    }
}

fn printToken(token: Token) !void {
    const typeName = @tagName(token.type);
    try std.io.getStdOut().writer().print("{s} {s} {any}\n", .{ typeName, token.lexeme, token.literal });
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    var exit_code: u8 = 0;

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
        var line: u8 = 1;
        for (file_contents) |i| {
            if (i == '\n') {
                line += 1;
                continue;
            }

            if (scanToken(i)) |token| {
                try printToken(token);
            } else |err| {
                if (err == error.InvalidCharacter) {
                    std.debug.print("[line {}] Error: Unexpected character: {c}\n", .{ line, i });
                    exit_code = 65;
                }
            }
        }
    }

    if (scanToken(0)) |token| {
        try printToken(token);
    } else |err| {
        std.debug.print("Error at EOF: {}\n", .{err});
        exit_code = 65;
    }

    std.process.exit(exit_code);
}
