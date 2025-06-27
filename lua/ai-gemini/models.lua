-- lua/ai-gemini/models.lua

local M = {}
local current_api_keys = {} -- Akan diisi dari setup

-- Fungsi ini dipanggil dari init.lua, menerima API keys dari user_opts
function M.get_all_models(api_keys_from_opts)
    current_api_keys = api_keys_from_opts or {}

    -- Definisi Model Gemini via Google API
    M.Gemini = {
        name = "Google Gemini",
        name_alias = "Gemini",
        url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
        model = "gemini-pro",
        api_type = "google_gemini",
        max_tokens = 4096,
        temperature = 0.7,
        top_p = 0.9,
        -- Mengambil key langsung dari tabel current_api_keys
        fetch_key = function()
            return current_api_keys.gemini
        end,
    }

    -- Definisi Model OpenAI (atau kompatibel dengan OpenAI API)
    M.ChatAnywhere = {
        name = "ChatAnywhere GPT-4o",
        name_alias = "ChatAnywhere",
        url = "https://api.chatanywhere.tech/v1/chat/completions",
        model = "gpt-4o",
        api_type = "openai",
        max_tokens = 8000,
        temperature = 0.3,
        top_p = 0.7,
        -- Mengambil key langsung dari tabel current_api_keys
        fetch_key = function()
            return current_api_keys.chat_anywhere
        end,
    }

    -- Definisi Ollama (Local LLM)
    M.Ollama = {
        name = "Ollama Local LLM",
        name_alias = "Ollama",
        url = "http://localhost:11434/api/chat",
        model = "llama3",
        api_type = "ollama",
        temperature = 0.3,
        fetch_key = function()
            return current_api_keys.ollama or "" -- Ollama umumnya tidak memerlukan API key
        end,
    }

    local models_list = {}
    for _, model_data in pairs(M) do
        if type(model_data) == "table" and model_data.name and model_data.name_alias then
            table.insert(models_list, model_data)
        end
    }
    return models_list
end

return M
