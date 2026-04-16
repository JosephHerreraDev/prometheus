-- db   d8b   db d888888b d8b   db d8888b.  .d88b.  db   d8b   db .d8888.   
-- 88   I8I   88   `88'   888o  88 88  `8D .8P  Y8. 88   I8I   88 88'  YP   
-- 88   I8I   88    88    88V8o 88 88   88 88    88 88   I8I   88 `8bo.     
-- Y8   I8I   88    88    88 V8o88 88   88 88    88 Y8   I8I   88   `Y8b.   
-- `8b d8'8b d8'   .88.   88  V888 88  .8D `8b  d8' `8b d8'8b d8' db   8D   
--  `8b8' `8d8'  Y888888P VP   V8P Y8888D'  `Y88P'   `8b8' `8d8'  `8888Y'   
--                                                                          
--                                                                          
-- d8888b.  .d8b.  d8888b. db   dD      .88b  d88.  .d88b.  d8888b. d88888b 
-- 88  `8D d8' `8b 88  `8D 88 ,8P'      88'YbdP`88 .8P  Y8. 88  `8D 88'     
-- 88   88 88ooo88 88oobY' 88,8P        88  88  88 88    88 88   88 88ooooo 
-- 88   88 88~~~88 88`8b   88`8b        88  88  88 88    88 88   88 88~~~~~ 
-- 88  .8D 88   88 88 `88. 88 `88.      88  88  88 `8b  d8' 88  .8D 88.     
-- Y8888D' YP   YP 88   YD YP   YD      YP  YP  YP  `Y88P'  Y8888D' Y88888P 
--                                                                          
--                                                                          

return {
    {
        "bjarneo/aether.nvim",
        branch = "v2",
        name = "aether",
        priority = 1000,
        opts = {
            transparent = false,
            colors = {
                -- Background colors
                bg = "#181818",
                bg_dark = "#181818",
                bg_highlight = "#616161",

                -- Foreground colors
                -- fg: Object properties, builtin types, builtin variables, member access, default text
                fg = "#ffffff",
                -- fg_dark: Inactive elements, statusline, secondary text
                fg_dark = "#cccccc",
                -- comment: Line highlight, gutter elements, disabled states
                comment = "#616161",

                -- Accent colors
                -- red: Errors, diagnostics, tags, deletions, breakpoints
                red = "#f85149",
                -- orange: Constants, numbers, current line number, git modifications
                orange = "#f85149",
                -- yellow: Types, classes, constructors, warnings, numbers, booleans
                yellow = "#bb8009",
                -- green: Comments, strings, success states, git additions
                green = "#2ea043",
                -- cyan: Parameters, regex, preprocessor, hints, properties
                cyan = "#4daafc",
                -- blue: Functions, keywords, directories, links, info diagnostics
                blue = "#0078d4",
                -- purple: Storage keywords, special keywords, identifiers, namespaces
                purple = "#c586c0",
                -- magenta: Function declarations, exception handling, tags
                magenta = "#c586c0",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}

--  ______   __       ______                                       
-- /_____/\ /_/\     /_____/\                                      
-- \:::_ \ \\:\ \    \:::_ \ \                                     
--  \:\ \ \ \\:\ \    \:\ \ \ \                                    
--   \:\ \ \ \\:\ \____\:\ \ \ \                                   
--    \:\_\ \ \\:\/___/\\:\/.:| |                                  
--  ___\_____\/_\_____\/ \____/_/  ______    _______   ______      
-- /________/\/_____/\ /_______/\ /_____/\ /_______/\ /_____/\     
-- \__.::.__\/\:::_ \ \\::: _  \ \\:::_ \ \\::: _  \ \\:::_ \ \    
--   /_\::\ \  \:\ \ \ \\::(_)  \/_\:\ \ \ \\::(_)  \/_\:\ \ \ \   
--   \:.\::\ \  \:\ \ \ \\::  _  \ \\:\ \ \ \\::  _  \ \\:\ \ \ \  
--    \: \  \ \  \:\_\ \ \\::(_)  \ \\:\_\ \ \\::(_)  \ \\:\_\ \ \ 
--     \_____\/   \_____\/ \_______\/ \_____\/ \_______\/ \_____\/ 
--                                                                 