-- =============================================================
-- kipferl.lua — Neko Kipferl colorscheme for Neovim
-- Place at: ~/.config/nvim/colors/kipferl.lua
-- Usage:    vim.cmd("colorscheme kipferl")
-- =============================================================

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
vim.g.colors_name = "kipferl"
vim.o.termguicolors = true
vim.o.background = "dark"

-- ── Palette ───────────────────────────────────────────────────
local c = {
  -- bg scale
  bg_dim    = "#3C2E1E",
  bg0       = "#483820",
  bg1       = "#544228",
  bg2       = "#604C30",
  bg3       = "#6C5838",
  bg4       = "#786448",
  bg_visual = "#504028",
  bg_red    = "#583028",
  bg_green  = "#304838",
  bg_blue   = "#284858",
  bg_yellow = "#483808",

  -- fg / text
  fg        = "#F0D8A0",
  fg_dim    = "#C0A888",
  fg_muted  = "#A88870",

  -- accents
  red       = "#D06858",
  orange    = "#C8905A",
  yellow    = "#D8C070",
  green     = "#7A9878",
  aqua      = "#70A8A0",
  blue      = "#8098B8",
  purple    = "#B890A0",

  -- greys
  grey0     = "#907060",
  grey1     = "#A88870",
  grey2     = "#C0A888",

  -- special
  none      = "NONE",

  -- another ---
  comment   = "#8A9878"
}

-- ── Helper ────────────────────────────────────────────────────
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- =============================================================
-- EDITOR
-- =============================================================
hi("Normal",        { fg = c.fg,       bg = c.bg0 })
hi("NormalNC",      { fg = c.fg_dim,   bg = c.bg_dim })
hi("NormalFloat",   { fg = c.fg,       bg = c.bg1 })
hi("FloatBorder",   { fg = c.bg4,      bg = c.bg1 })
hi("FloatTitle",    { fg = c.aqua,     bg = c.bg1, bold = true })

hi("Cursor",        { fg = c.bg0,      bg = c.fg })
hi("CursorLine",    { bg = c.bg1 })
hi("CursorLineNr",  { fg = c.orange,   bg = c.bg1, bold = true })
hi("CursorColumn",  { bg = c.bg1 })

hi("LineNr",        { fg = c.grey0 })
hi("SignColumn",    { fg = c.grey0,    bg = c.bg0 })
hi("ColorColumn",   { bg = c.bg1 })
hi("FoldColumn",    { fg = c.grey0,    bg = c.bg0 })
hi("Folded",        { fg = c.grey1,    bg = c.bg1 })

hi("StatusLine",    { fg = c.fg,       bg = c.bg_visual })
hi("StatusLineNC",  { fg = c.fg_muted, bg = c.bg_dim })
hi("WinBar",        { fg = c.fg,       bg = c.bg_visual })
hi("WinBarNC",      { fg = c.fg_muted, bg = c.bg_dim })
hi("WinSeparator",  { fg = c.bg3 })

hi("TabLine",       { fg = c.fg_muted, bg = c.bg_dim })
hi("TabLineSel",    { fg = c.fg,       bg = c.bg_visual, bold = true })
hi("TabLineFill",   { bg = c.bg_dim })

hi("Pmenu",         { fg = c.fg,       bg = c.bg1 })
hi("PmenuSel",      { fg = c.bg0,      bg = c.aqua, bold = true })
hi("PmenuSbar",     { bg = c.bg2 })
hi("PmenuThumb",    { bg = c.bg4 })

hi("Visual",        { bg = c.bg_visual })
hi("VisualNOS",     { bg = c.bg_visual })
hi("Search",        { fg = c.bg0,      bg = c.yellow, bold = true })
hi("IncSearch",     { fg = c.bg0,      bg = c.orange, bold = true })
hi("CurSearch",     { fg = c.bg0,      bg = c.orange, bold = true })
hi("Substitute",    { fg = c.bg0,      bg = c.red })

hi("MatchParen",    { fg = c.aqua,     bold = true, underline = true })
hi("NonText",       { fg = c.bg3 })
hi("Whitespace",    { fg = c.bg3 })
hi("SpecialKey",    { fg = c.bg3 })
hi("EndOfBuffer",   { fg = c.bg2 })

hi("Title",         { fg = c.orange,   bold = true })
hi("Directory",     { fg = c.aqua,     bold = true })
hi("Question",      { fg = c.yellow })
hi("MoreMsg",       { fg = c.green })
hi("ModeMsg",       { fg = c.fg,       bold = true })
hi("MsgArea",       { fg = c.fg })
hi("ErrorMsg",      { fg = c.red,      bold = true })
hi("WarningMsg",    { fg = c.yellow })

hi("Conceal",       { fg = c.grey0 })
hi("Ignore",        { fg = c.grey0 })
hi("Underlined",    { underline = true })
hi("Bold",          { bold = true })
hi("Italic",        { italic = true })

-- Spell
hi("SpellBad",      { undercurl = true, sp = c.red })
hi("SpellCap",      { undercurl = true, sp = c.blue })
hi("SpellRare",     { undercurl = true, sp = c.purple })
hi("SpellLocal",    { undercurl = true, sp = c.aqua })

-- Diff
hi("DiffAdd",       { fg = c.green,    bg = c.bg_green })
hi("DiffChange",    { fg = c.blue,     bg = c.bg_blue })
hi("DiffDelete",    { fg = c.red,      bg = c.bg_red })
hi("DiffText",      { fg = c.yellow,   bg = c.bg_yellow, bold = true })
hi("Added",         { fg = c.green })
hi("Changed",       { fg = c.blue })
hi("Removed",       { fg = c.red })

-- =============================================================
-- SYNTAX
-- =============================================================
hi("Comment",       { fg = c.grey0,    italic = true })
hi("Constant",      { fg = c.purple })
hi("String",        { fg = c.green })
hi("Character",     { fg = c.green })
hi("Number",        { fg = c.purple })
hi("Boolean",       { fg = c.orange,   bold = true })
hi("Float",         { fg = c.purple })

hi("Identifier",    { fg = c.fg })
hi("Function",      { fg = c.aqua,     bold = true })

hi("Statement",     { fg = c.orange })
hi("Conditional",   { fg = c.orange })
hi("Repeat",        { fg = c.orange })
hi("Label",         { fg = c.orange })
hi("Operator",      { fg = c.yellow })
hi("Keyword",       { fg = c.orange,   bold = true })
hi("Exception",     { fg = c.red })

hi("PreProc",       { fg = c.yellow })
hi("Include",       { fg = c.yellow })
hi("Define",        { fg = c.yellow })
hi("Macro",         { fg = c.yellow })
hi("PreCondit",     { fg = c.yellow })

hi("Type",          { fg = c.yellow })
hi("StorageClass",  { fg = c.orange })
hi("Structure",     { fg = c.yellow })
hi("Typedef",       { fg = c.yellow })

hi("Special",       { fg = c.aqua })
hi("SpecialChar",   { fg = c.aqua })
hi("Tag",           { fg = c.aqua })
hi("Delimiter",     { fg = c.fg_muted })
hi("SpecialComment",{ fg = c.grey1,    italic = true })
hi("Debug",         { fg = c.red })

hi("Error",         { fg = c.red,      bold = true })
hi("Todo",          { fg = c.bg0,      bg = c.yellow, bold = true })

-- =============================================================
-- DIAGNOSTIC
-- =============================================================
hi("DiagnosticError",       { fg = c.red })
hi("DiagnosticWarn",        { fg = c.yellow })
hi("DiagnosticInfo",        { fg = c.blue })
hi("DiagnosticHint",        { fg = c.aqua })
hi("DiagnosticOk",          { fg = c.green })
hi("DiagnosticUnderlineError",  { undercurl = true, sp = c.red })
hi("DiagnosticUnderlineWarn",   { undercurl = true, sp = c.yellow })
hi("DiagnosticUnderlineInfo",   { undercurl = true, sp = c.blue })
hi("DiagnosticUnderlineHint",   { undercurl = true, sp = c.aqua })
hi("DiagnosticVirtualTextError",{ fg = c.red,    bg = c.bg_red,    italic = true })
hi("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = c.bg_yellow, italic = true })
hi("DiagnosticVirtualTextInfo", { fg = c.blue,   bg = c.bg_blue,   italic = true })
hi("DiagnosticVirtualTextHint", { fg = c.aqua,   bg = c.bg_green,  italic = true })
hi("DiagnosticSignError",   { fg = c.red,    bg = c.bg0 })
hi("DiagnosticSignWarn",    { fg = c.yellow, bg = c.bg0 })
hi("DiagnosticSignInfo",    { fg = c.blue,   bg = c.bg0 })
hi("DiagnosticSignHint",    { fg = c.aqua,   bg = c.bg0 })

-- =============================================================
-- LSP
-- =============================================================
hi("LspReferenceText",      { bg = c.bg2 })
hi("LspReferenceRead",      { bg = c.bg2 })
hi("LspReferenceWrite",     { bg = c.bg2, underline = true })
hi("LspInlayHint",          { fg = c.grey0, italic = true })
hi("LspCodeLens",           { fg = c.grey0, italic = true })

-- =============================================================
-- TREESITTER
-- =============================================================
hi("@comment",              { link = "Comment" })
hi("@comment.documentation",{ fg = c.comment, italic = true })
hi("@keyword",              { link = "Keyword" })
hi("@keyword.function",     { fg = c.orange, bold = true })
hi("@keyword.operator",     { fg = c.yellow })
hi("@keyword.return",       { fg = c.orange, italic = true })
hi("@keyword.import",       { fg = c.yellow })
hi("@conditional",          { link = "Conditional" })
hi("@repeat",               { link = "Repeat" })
hi("@operator",             { link = "Operator" })
hi("@punctuation.delimiter",{ fg = c.fg_muted })
hi("@punctuation.bracket",  { fg = c.grey2 })
hi("@punctuation.special",  { fg = c.aqua })

hi("@string",               { link = "String" })
hi("@string.escape",        { fg = c.aqua })
hi("@string.special",       { fg = c.aqua })
hi("@string.regex",         { fg = c.aqua })
hi("@character",            { link = "Character" })
hi("@number",               { link = "Number" })
hi("@float",                { link = "Float" })
hi("@boolean",              { link = "Boolean" })

hi("@function",             { link = "Function" })
hi("@function.builtin",     { fg = c.aqua })
hi("@function.call",        { fg = c.aqua })
hi("@function.macro",       { fg = c.yellow })
hi("@method",               { fg = c.aqua })
hi("@method.call",          { fg = c.aqua })
hi("@constructor",          { fg = c.yellow })
hi("@parameter",            { fg = c.fg })

hi("@variable",             { fg = c.fg })
hi("@variable.builtin",     { fg = c.orange, italic = true })
hi("@variable.parameter",   { fg = c.fg })
hi("@variable.member",      { fg = c.fg_dim })

hi("@type",                 { link = "Type" })
hi("@type.builtin",         { fg = c.yellow, italic = true })
hi("@type.definition",      { fg = c.yellow })
hi("@namespace",            { fg = c.yellow })
hi("@module",               { fg = c.yellow })

hi("@constant",             { link = "Constant" })
hi("@constant.builtin",     { fg = c.purple, bold = true })
hi("@constant.macro",       { fg = c.yellow })

hi("@attribute",            { fg = c.yellow })
hi("@label",                { fg = c.orange })
hi("@exception",            { fg = c.red })

hi("@tag",                  { fg = c.orange })
hi("@tag.attribute",        { fg = c.yellow })
hi("@tag.delimiter",        { fg = c.fg_muted })

hi("@diff.plus",            { link = "DiffAdd" })
hi("@diff.minus",           { link = "DiffDelete" })
hi("@diff.delta",           { link = "DiffChange" })

-- =============================================================
-- TELESCOPE
-- =============================================================
hi("TelescopeNormal",           { fg = c.fg,       bg = c.bg1 })
hi("TelescopeBorder",           { fg = c.bg4,      bg = c.bg1 })
hi("TelescopeTitle",            { fg = c.aqua,     bg = c.bg1, bold = true })
hi("TelescopePromptNormal",     { fg = c.fg,       bg = c.bg2 })
hi("TelescopePromptBorder",     { fg = c.bg4,      bg = c.bg2 })
hi("TelescopePromptTitle",      { fg = c.orange,   bg = c.bg2, bold = true })
hi("TelescopePromptPrefix",     { fg = c.orange })
hi("TelescopePromptCounter",    { fg = c.grey1 })
hi("TelescopeResultsNormal",    { fg = c.fg,       bg = c.bg1 })
hi("TelescopeResultsBorder",    { fg = c.bg4,      bg = c.bg1 })
hi("TelescopeResultsTitle",     { fg = c.fg_muted, bg = c.bg1 })
hi("TelescopePreviewNormal",    { fg = c.fg,       bg = c.bg_dim })
hi("TelescopePreviewBorder",    { fg = c.bg4,      bg = c.bg_dim })
hi("TelescopePreviewTitle",     { fg = c.green,    bg = c.bg_dim, bold = true })
hi("TelescopeSelection",        { fg = c.fg,       bg = c.bg_visual })
hi("TelescopeSelectionCaret",   { fg = c.orange,   bg = c.bg_visual })
hi("TelescopeMultiSelection",   { fg = c.aqua })
hi("TelescopeMatching",         { fg = c.yellow,   bold = true })

-- =============================================================
-- NVIM-CMP
-- =============================================================
hi("CmpNormal",                 { fg = c.fg,       bg = c.bg1 })
hi("CmpBorder",                 { fg = c.bg4 })
hi("CmpItemAbbr",               { fg = c.fg })
hi("CmpItemAbbrDeprecated",     { fg = c.grey0,    strikethrough = true })
hi("CmpItemAbbrMatch",          { fg = c.yellow,   bold = true })
hi("CmpItemAbbrMatchFuzzy",     { fg = c.yellow })
hi("CmpItemMenu",               { fg = c.grey1,    italic = true })
hi("CmpItemKindText",           { fg = c.fg })
hi("CmpItemKindMethod",         { fg = c.aqua })
hi("CmpItemKindFunction",       { fg = c.aqua })
hi("CmpItemKindConstructor",    { fg = c.yellow })
hi("CmpItemKindField",          { fg = c.fg_dim })
hi("CmpItemKindVariable",       { fg = c.fg })
hi("CmpItemKindClass",          { fg = c.yellow })
hi("CmpItemKindInterface",      { fg = c.yellow })
hi("CmpItemKindModule",         { fg = c.yellow })
hi("CmpItemKindProperty",       { fg = c.fg_dim })
hi("CmpItemKindUnit",           { fg = c.purple })
hi("CmpItemKindValue",          { fg = c.purple })
hi("CmpItemKindEnum",           { fg = c.yellow })
hi("CmpItemKindKeyword",        { fg = c.orange })
hi("CmpItemKindSnippet",        { fg = c.green })
hi("CmpItemKindColor",          { fg = c.aqua })
hi("CmpItemKindFile",           { fg = c.fg_dim })
hi("CmpItemKindReference",      { fg = c.blue })
hi("CmpItemKindFolder",         { fg = c.aqua })
hi("CmpItemKindEnumMember",     { fg = c.purple })
hi("CmpItemKindConstant",       { fg = c.purple })
hi("CmpItemKindStruct",         { fg = c.yellow })
hi("CmpItemKindEvent",          { fg = c.orange })
hi("CmpItemKindOperator",       { fg = c.yellow })
hi("CmpItemKindTypeParameter",  { fg = c.yellow })

-- =============================================================
-- LUALINE  (return theme table)
-- =============================================================
-- Usage in lualine setup:
--   require("lualine").setup({ options = { theme = require("kipferl").lualine } })

local lualine = {
  normal = {
    a = { fg = c.bg0,  bg = c.aqua,   gui = "bold" },
    b = { fg = c.fg,   bg = c.bg2 },
    c = { fg = c.fg,   bg = c.bg_visual },
  },
  insert = {
    a = { fg = c.bg0,  bg = c.green,  gui = "bold" },
    b = { fg = c.fg,   bg = c.bg2 },
    c = { fg = c.fg,   bg = c.bg_visual },
  },
  visual = {
    a = { fg = c.bg0,  bg = c.purple, gui = "bold" },
    b = { fg = c.fg,   bg = c.bg2 },
    c = { fg = c.fg,   bg = c.bg_visual },
  },
  replace = {
    a = { fg = c.bg0,  bg = c.red,    gui = "bold" },
    b = { fg = c.fg,   bg = c.bg2 },
    c = { fg = c.fg,   bg = c.bg_visual },
  },
  command = {
    a = { fg = c.bg0,  bg = c.yellow, gui = "bold" },
    b = { fg = c.fg,   bg = c.bg2 },
    c = { fg = c.fg,   bg = c.bg_visual },
  },
  inactive = {
    a = { fg = c.grey0, bg = c.bg_dim },
    b = { fg = c.grey0, bg = c.bg_dim },
    c = { fg = c.grey0, bg = c.bg_dim },
  },
}

return { lualine = lualine, colors = c }
