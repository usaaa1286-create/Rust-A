package com.rustskinanalyzer.domain

/**
 * Проста, але надійна перевірка "чи згадується цей скін у тексті відео".
 * MVP-підхід: нормалізуємо обидва рядки (нижній регістр, без пунктуації) і
 * перевіряємо, чи всі значущі слова назви скіну присутні в тексті.
 * Це навмисно простіше за ML/NLP-рішення — легко пояснити хибні спрацювання
 * і легко покращувати список стоп-слів вручну.
 */
object SkinNameMatcher {

    private val stopWords = setOf("the", "a", "an", "rust", "skin", "|")

    fun normalize(text: String): List<String> =
        text.lowercase()
            .replace(Regex("[^a-z0-9\\s|]"), " ")
            .split(Regex("\\s+"))
            .filter { it.isNotBlank() && it !in stopWords }

    /**
     * @param skinDisplayName напр. "AK-47 | Redline" (без стану зношеності)
     * @param text заголовок + опис відео
     */
    fun isMentioned(skinDisplayName: String, text: String): Boolean {
        val skinTokens = normalize(skinDisplayName)
        if (skinTokens.isEmpty()) return false
        val textTokens = normalize(text).toSet()
        // вимагаємо збіг щонайменше 80% значущих слів назви скіну (округлення вгору)
        val required = ((skinTokens.size * 0.8).toInt()).coerceAtLeast(skinTokens.size - 1).coerceAtLeast(1)
        val matched = skinTokens.count { it in textTokens }
        return matched >= required
    }

    /** Формує пошуковий запит для YouTube Data API. */
    fun buildSearchQuery(weapon: String, skinDisplayName: String): String =
        "rust $weapon $skinDisplayName skin"
}
