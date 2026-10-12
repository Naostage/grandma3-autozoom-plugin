// Runs test/autozoom.test.lua in fengari (pure JS Lua 5.3) against the compiled plugin bundle.
const { lua, lauxlib, lualib, to_luastring } = require("fengari");
const path = require("path");

process.chdir(path.join(__dirname, ".."));

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

if (lauxlib.luaL_dofile(L, to_luastring("test/autozoom.test.lua")) !== lua.LUA_OK) {
    console.error(lua.lua_tojsstring(L, -1));
    process.exit(1);
}
