-- lua/ai-gemini/init.lua

local M = {}

-- Muat modul internal
local config = require("ai-gemini.config")
local models = require("ai-gemini.models")
local api = require("ai-gemini.api")
local ui = require("ai-gemini.ui")

-- Opsi plugin yang akan diakses di seluruh modul
M.opts = {}

-- Fungsi setup utama plugin
function M.setup(user_opts)
    -- Gabungkan konfigurasi default dengan konfigurasi pengguna
    -- user_opts sekarang akan mencakup api_keys
    M.opts = vim.tbl_deep_extend("force", config.get_default_config(), user_opts or {})

    -- Tambahkan definisi model ke opsi, dan teruskan api_keys
    M.opts.models_data = models.get_all_models(M.opts.api_keys) -- Teruskan api_keys ke models.lua

    -- Set up API handler dengan konfigurasi yang sudah digabungkan
    api.setup(M.opts)
    ui.setup(M.opts)

    vim.notify("AI-Gemini: Plugin loaded and configured!", vim.log.levels.INFO)
end

-- Fungsi publik untuk memulai sesi chat
function M.start_chat_session()
    ui.open_chat_window()
end

-- Fungsi publik untuk menangani permintaan AI (misal, menjelaskan kode)
function M.handle_ai_request(prompt, selected_text, callback)
    local active_model_name = M.opts.default_model or "ChatAnywhere"
    local model_config = nil

    for _, model in ipairs(M.opts.models_data) do
        if model.name_alias == active_model_name then
            model_config = model
            break
        end
    end

    if not model_config then
        vim.notify("AI-Gemini: Default model '" .. active_model_name .. "' not found in config.", vim.log.levels.ERROR)
        return
    end

    ui.show_spinner()

    api.send_chat_request(model_config, prompt, selected_text, function(success, response_content)
        ui.hide_spinner()
        if success then
            vim.notify("AI-Gemini: Request successful!", vim.log.levels.INFO)
            if callback then
                callback(response_content)
            end
        else
            vim.notify("AI-Gemini: Request failed. Error: " .. response_content, vim.log.levels.ERROR)
        end
    end)
end

return M
