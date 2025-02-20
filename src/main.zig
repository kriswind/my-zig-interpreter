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
    STAR,

    // One or two character tokens.
    SLASH,
    SLASH_SLASH,
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
    literal: []const u8,
};

const ScanResult = struct {
    token: ?Token,
    consumed: usize,
};

fn addToken(tokenType: TokenType, lexeme: []const u8, literal: []const u8) Token {
    return Token{ .type = tokenType, .lexeme = lexeme, .literal = literal };
}

fn scanToken(line: []const u8, index: usize) !ScanResult {
    if (index >= line.len) {
        return error.EndOfInput;
    }

    const curr_char = line[index];
    const next_char: u8 = if (index + 1 < line.len) line[index + 1] else 0;

    switch (curr_char) {
        '!' => {
            if (next_char == '=') return ScanResult{ .token = addToken(.BANG_EQUAL, "!=", "null"), .consumed = 2 };
            return ScanResult{ .token = addToken(.BANG, "!", "null"), .consumed = 1 };
        },
        '=' => {
            if (next_char == '=') return ScanResult{ .token = addToken(.EQUAL_EQUAL, "==", "null"), .consumed = 2 };
            return ScanResult{ .token = addToken(.EQUAL, "=", "null"), .consumed = 1 };
        },
        '<' => {
            if (next_char == '=') return ScanResult{ .token = addToken(.LESS_EQUAL, "<=", "null"), .consumed = 2 };
            return ScanResult{ .token = addToken(.LESS, "<", "null"), .consumed = 1 };
        },
        '>' => {
            if (next_char == '=') return ScanResult{ .token = addToken(.GREATER_EQUAL, ">=", "null"), .consumed = 2 };
            return ScanResult{ .token = addToken(.GREATER, ">", "null"), .consumed = 1 };
        },
        '/' => {
            if (next_char == '/') return ScanResult{ .token = addToken(.SLASH_SLASH, "//", "null"), .consumed = 2 };
            return ScanResult{ .token = addToken(.SLASH, "/", "null"), .consumed = 1 };
        },
        '(' => return ScanResult{ .token = addToken(.LEFT_PAREN, "(", "null"), .consumed = 1 },
        ')' => return ScanResult{ .token = addToken(.RIGHT_PAREN, ")", "null"), .consumed = 1 },
        '{' => return ScanResult{ .token = addToken(.LEFT_BRACE, "{", "null"), .consumed = 1 },
        '}' => return ScanResult{ .token = addToken(.RIGHT_BRACE, "}", "null"), .consumed = 1 },
        '*' => return ScanResult{ .token = addToken(.STAR, "*", "null"), .consumed = 1 },
        '.' => return ScanResult{ .token = addToken(.DOT, ".", "null"), .consumed = 1 },
        ',' => return ScanResult{ .token = addToken(.COMMA, ",", "null"), .consumed = 1 },
        '+' => return ScanResult{ .token = addToken(.PLUS, "+", "null"), .consumed = 1 },
        '-' => return ScanResult{ .token = addToken(.MINUS, "-", "null"), .consumed = 1 },
        ';' => return ScanResult{ .token = addToken(.SEMICOLON, ";", "null"), .consumed = 1 },
        '"' => {
            var end: usize = index + 1;
            while (end < line.len and line[end] != '"') {
                end += 1;
            }

            if (end == line.len) {
                return error.UnterminatedString;
            }

            const literal = line[index + 1 .. end];
            return ScanResult{ .token = addToken(.STRING, line[index .. end + 1], literal), .consumed = end - index + 1 };
        },
        ' ', '\t', '\r', '\n' => return ScanResult{ .token = null, .consumed = 1 },
        else => return error.InvalidCharacter,
    }
}

fn printToken(token: Token) !void {
    const typeName = @tagName(token.type);
    try std.io.getStdOut().writer().print("{s} {s} {s}\n", .{ typeName, token.lexeme, token.literal });
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
        var start: usize = 0;

        while (start < file_contents.len) {
            // Extract the current line
            var end: usize = start;
            while (end < file_contents.len and file_contents[end] != '\n') {
                end += 1;
            }

            const lineSlice = file_contents[start..end]; // Extract line

            var index: usize = 0;
            while (index < lineSlice.len) {
                if (scanToken(lineSlice, index)) |result| {
                    const token = result.token;
                    const consumed = result.consumed;

                    if (token) |t| { // Unwrap the optional safely
                        if (t.type == .SLASH_SLASH) {
                            break; // Skip rest of the comment line
                        }
                        try printToken(t);
                    }
                    index += consumed;
                } else |err| {
                    if (err == error.InvalidCharacter) {
                        std.debug.print("[line {}] Error: Unexpected character: {c}\n", .{ line, lineSlice[index] });
                        exit_code = 65;
                        index += 1;
                    } else if (err == error.UnterminatedString) {
                        std.debug.print("[line {}] Error: Unterminated string.\n", .{line});
                        exit_code = 65;
                        break;
                    } else if (err == error.EndOfInput) {
                        break;
                    }
                }
            }

            start = end + 1; // Move to next line
            line += 1;
        }
    }

    const eof_token = addToken(.EOF, "", "null");
    try printToken(eof_token);

    std.process.exit(exit_code);
}
