pub const Error = error{ GenericError, SomethingElse };
// const Error = struct {
//     status: u16, // 400-599
//     message: []const u8,
// };

// Documented Status Codes
// https://developer.spotify.com/documentation/web-api/concepts/api-calls
// 400, 401, 403, 404, 429, 500, 502, 503
