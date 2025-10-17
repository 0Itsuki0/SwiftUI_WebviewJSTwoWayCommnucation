import { useCallback, useEffect, useState } from 'react'
import { useTheme } from './helpers/use-theme'


function App() {

    const windowDefined = typeof window === "undefined"

    const theme = useTheme()
    const [showUI, setShowUI] = useState<boolean>(false)
    const [number, setNumber] = useState<number | null>(null)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        if (typeof window === "undefined") {
            setShowUI(false)
            return
        }
        if (!window.itsuki) {
            setShowUI(false)
            return
        }
        setShowUI(true)
    }, [windowDefined, window?.itsuki])

    const getRandomInt = useCallback(function getRandomInt(): number {
        return Math.floor(Math.random() * 10)
    }, [])

    if (!showUI) {
        return (
            <div className='flex flex-col gap-4 bg-amber-100 border rounded-md border-amber-700 text-black p-4 m-auto w-full h-[60vh] justify-center max-w-2xl font-semibold items-center text-xl' >
                Itsuki Undefined!
            </div>)
    }

    const textStyle = theme === "dark" ? "text-white" : "text-black"

    return (
        <div className={`flex flex-col gap-2 border rounded-md p-4 m-auto w-full h-fit justify-center max-w-2xl ${theme === "dark" ? "bg-black" : "bg-amber-100"}`}>
            <div className={`flex flex-col gap-2`}>
                <span className={`${textStyle} font-semibold`}>Notify SwiftUI on Set & Settable from Swifts-side</span>
                <div className='flex flex-row gap-2 items-center'>
                    <button
                        className={`border rounded-md  py-1 px-2  w-fit " ${theme === "dark" ? "bg-white text-black" : "bg-black text-white"}`}
                        onClick={() => {
                            console.log("clicked")
                            window.itsuki?.setTheme(theme === "dark" ? "light" : "dark")
                        }}>
                        Change Theme
                    </button>
                    <span className={`${textStyle}`}>Theme: {theme === null ? "null" : theme}</span>
                </div>
            </div>

            <div className={`${theme === "dark" ? "bg-white" : "bg-black"} h-[1px] w-full rounded-md my-2`}></div>

            <div className={`flex flex-col gap-2`}>
                <span className={`${textStyle} font-semibold`}>Get Return Value from Swift Functions (Async/Throws)</span>

                <div className='flex flex-row gap-2 items-center'>
                    <button
                        className={`border rounded-md  py-1 px-2  w-fit" ${theme === "dark" ? "bg-white text-black" : "bg-black text-white"}`}
                        onClick={async () => {
                            const number = await window.itsuki?.callFunction("multiplier", {
                                values: [getRandomInt(), getRandomInt()]
                            })
                            if (typeof number === "number") {
                                setNumber(number)
                            }
                        }}>
                        Multiply 2 Random Number
                    </button>
                    {
                        number !== null ? <span className={`font-semibold ${textStyle}`}>Number: {number}</span> : null
                    }
                </div>

                <div className='flex flex-row gap-2 items-center'>
                    <button
                        className={`border rounded-md py-1 px-2 w-fit min-w-fit" ${theme === "dark" ? "bg-red-300 text-black" : "bg-red-600 text-white"}`}
                        onClick={async () => {
                            try {
                                await window.itsuki?.callFunction("getError", {})
                            } catch (error) {
                                const detail = error instanceof Error ? error.message : `${error}`
                                setError(detail)
                            }
                        }}>
                        Get An Error
                    </button>
                    {
                        error !== null ? <span className={`font-semibold ${textStyle}`}>Error: {error}</span> : null
                    }
                </div>

            </div>


        </div>
    )
}

export default App
