-- lua/ai-gemini/config.lua

local M = {}

function M.get_default_config()
    return {
        prompt = "You are a helpful AI assistant.",
        default_model = "ChatAnywhere",
        spinner = {
            text = { "󰧞󰧞", "󰧞󰧞", "󰧞󰧞" },
            hl = "Title",
        },
        prefix = {
            user = { text = "  ", hl = "Title" },
            assistant = { text = "  ", hl = "Added" },
        },
        chat_window = {
            width = "80%",
            height = "60%",
            relative = "editor",
            position = "center",
            border = {
                style = "single",
                text = { top = " AI Gemini Chat ", top_align = "center" },
            },
            win_options = {
                winblend = 0,
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
        },
        save_session = true,
        max_history = 10,
        max_history_name_length = 20,
        timeout = 30,
        enable_trace = false,
        log_level = vim.log.levels.INFO,
        -- api_keys = {}, -- Ini tidak lagi di default_config, tapi akan disupply dari Lazy
    }
end

return M
