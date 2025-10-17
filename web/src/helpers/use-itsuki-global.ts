import { useSyncExternalStore } from "react"
import {
    SET_GLOBALS_EVENT_TYPE,
    SetGlobalsEvent,
    type ItsukiGlobals,
} from "./types"

export function useItsukiGlobal<K extends keyof ItsukiGlobals>(
    key: K
): ItsukiGlobals[K] | null {
    return useSyncExternalStore(
        (onChange) => {
            if (typeof window === "undefined") {
                return () => { }
            }

            const handleSetGlobal = (event: SetGlobalsEvent) => {
                const value = event.detail.globals[key]
                if (value === undefined) {
                    return
                }

                onChange()
            }

            window.addEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal, {
                passive: true,
            })

            return () => {
                window.removeEventListener(SET_GLOBALS_EVENT_TYPE, handleSetGlobal)
            }
        },
        () => window.itsuki?.[key] ?? null,
        () => window.itsuki?.[key] ?? null
    )
}
