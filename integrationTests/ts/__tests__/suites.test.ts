jest.setTimeout(3000000)

import {
    loadData,
    executeSuite,
} from './suites'

describe('Test suites', () => {
    const data = loadData('suites.json')

    it.only(data.suites[data.suites.length - 1].description, async () => {
        const result = await executeSuite(data.suites[data.suites.length - 1], expect)
        console.log(result)

        expect(result).toBeTruthy()
    })

    for (const test of data.suites) {
        it(test.description, async () => {
            const result = await executeSuite(test, expect)
            console.log(result)

            expect(result).toBeTruthy()
        })
    }
})
