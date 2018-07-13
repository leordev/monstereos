const john = require("./july5/john.json");
const leo = require("./july5/leo.json");
const fried = require('./july5/friedger.json');
const fs = require('fs')

// BlockShare is a framework designed to distribute donations from end users to
// the projects dev team.


const approvedMembers = {
    1: "John",
    2: "Leo", 
    3: "Frieger"
}

const getTotalPoints = timeEntries => timeEntries.reduce((total, obj) => total += obj.timeSpent * obj.weight, 0)

const workSummaries = [john, leo, fried]

const getResults = (workSummaries, dividendAmount) => {

    console.log("Script ran with members")
    workSummaries.forEach(workSummary => console.log(approvedMembers[workSummary.teamMemberId]))

    // Adds property "totalPoints" which adds up all time entries with weight involved
    const addedUpWorkSummaries = workSummaries.map(workSummary => ({ ...workSummary, totalPoints: getTotalPoints(workSummary.timeEntries) }))
    // Finds all points created by all team members
    const totalPoints = addedUpWorkSummaries.reduce((total, workSummary) => total += workSummary.totalPoints, 0)
    
    // Adds percentage of the work pool
    const addedPercentages = addedUpWorkSummaries.map(workSummary => ({ ...workSummary, workPercentage: workSummary.totalPoints / totalPoints }))

    // Adds amount of EOS awarded
    const addedEosAward = addedPercentages.map(workSummary => ({ ...workSummary, eosAward: workSummary.workPercentage * dividendAmount })) 

    console.log(`Total dividend of ${dividendAmount} EOS`);
    addedEosAward.forEach(award => {
        console.log(`${approvedMembers[award.teamMemberId]} gets ${award.eosAward} EOS for doing ${(award.workPercentage * 100).toFixed(2)}% of the work.`)
    })

    const finalResults = {
        totalDividendAmount: dividendAmount,
        entries: addedEosAward
    }

    const json = JSON.stringify(finalResults)
    fs.writeFile("awards.json", json, "utf8", () => console.log('wrote file'));
}

getResults(workSummaries, 22)
