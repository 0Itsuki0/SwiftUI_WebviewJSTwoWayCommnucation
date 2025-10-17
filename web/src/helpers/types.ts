export type ItsukiGlobals = {
    theme: Theme
}

type API = {
    callFunction(name: AvailableFunctionName, value: Record<string, unknown>): Promise<unknown>
    setTheme(theme: Theme): void
}

export type Theme = "light" | "dark"

export type AvailableFunctionName = "multiplier" | "getError"

export const SET_GLOBALS_EVENT_TYPE = "itsuki:set_globals"
export class SetGlobalsEvent extends CustomEvent<{
    globals: Partial<ItsukiGlobals>
}> {
    readonly type = SET_GLOBALS_EVENT_TYPE
}

/**
 * Global object injected by the swiftUI App.
 */
declare global {
    interface Window {
        itsuki: API & ItsukiGlobals
    }

    interface WindowEventMap {
        [SET_GLOBALS_EVENT_TYPE]: SetGlobalsEvent
    }
}
