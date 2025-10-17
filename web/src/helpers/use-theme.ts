import type { Theme } from "./types"
import { useItsukiGlobal } from "./use-itsuki-global"

export function useTheme(): Theme | null {
    return useItsukiGlobal('theme')
}