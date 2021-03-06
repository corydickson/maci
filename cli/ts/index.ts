#!/usr/bin/env node

import * as argparse from 'argparse' 
import { 
    calcBinaryTreeDepthFromMaxLeaves,
    calcQuinTreeDepthFromMaxLeaves,
} from './utils'

import {
    genMaciKeypair,
    configureSubparser as configureSubparserForGenMaciKeypair,
} from './genMaciKeypair'

import {
    genMaciPubkey,
    configureSubparser as configureSubparserForGenMaciPubkey,
} from './genMaciPubkey'

import {
    create,
    configureSubparser as configureSubparserForCreate,
} from './create'

import {
    signup,
    configureSubparser as configureSubparserForSignup,
} from './signUp'

import {
    publish,
    configureSubparser as configureSubparserForPublish,
} from './publish'

import {
    processMessages,
    configureSubparser as configureSubparserForProcessMessages,
} from './process'

import {
    checkStateRoot,
    configureSubparser as configureSubparserForCheckStateRoot,
} from './checkStateRoot'

import {
    tally,
    configureSubparser as configureSubparserForTally,
} from './tally'

import {
    verify,
    configureSubparser as configureSubparserForVerify,
} from './verify'

import {
    processAndTallyWithoutProofs,
    configureSubparser as configureSubparserForPtwp,
} from './ptwp'

import {
    coordinatorReset,
    configureSubparser as configureSubparserForCoordinatorReset,
} from './coordinatorReset'

const main = async () => {
    const parser = new argparse.ArgumentParser({ 
        description: 'Minimal Anti-Collusion Infrastructure',
    })

    const subparsers = parser.addSubparsers({
        title: 'Subcommands',
        dest: 'subcommand',
    })

    // Subcommand: genMaciPubkey
    configureSubparserForGenMaciPubkey(subparsers)

    // Subcommand: genMaciKeypair
    configureSubparserForGenMaciKeypair(subparsers)

    // Subcommand: create
    configureSubparserForCreate(subparsers)

    // Subcommand: signup
    configureSubparserForSignup(subparsers)

    // Subcommand: publish
    configureSubparserForPublish(subparsers)
    
    // Subcommand: checkStateRoot
    configureSubparserForCheckStateRoot(subparsers)

    // Subcommand: process
    configureSubparserForProcessMessages(subparsers)

    // Subcommand: tally
    configureSubparserForTally(subparsers)

    // Subcommand: verify
    configureSubparserForVerify(subparsers)

    // Subcommand: processAndTallyWithoutProofs
    configureSubparserForPtwp(subparsers)

    // Subcommand: coordinatorReset
    configureSubparserForCoordinatorReset(subparsers)

    const args = parser.parseArgs()

    // Execute the subcommand method
    if (args.subcommand === 'genMaciKeypair') {
        await genMaciKeypair(args)
    } else if (args.subcommand === 'genMaciPubkey') {
        await genMaciPubkey(args)
    } else if (args.subcommand === 'create') {
        await create(args)
    } else if (args.subcommand === 'signup') {
        await signup(args)
    } else if (args.subcommand === 'publish') {
        await publish(args)
    } else if (args.subcommand === 'checkStateRoot') {
        await checkStateRoot(args)
    } else if (args.subcommand === 'process') {
        await processMessages(args)
        // Force the process to exit as it might get stuck
        process.exit()
    } else if (args.subcommand === 'tally') {
        await tally(args)
        // Force the process to exit as it might get stuck
        process.exit()
    } else if (args.subcommand === 'verify') {
        await verify(args)
    } else if (args.subcommand === 'processAndTallyWithoutProofs') {
        await processAndTallyWithoutProofs(args)
    } else if (args.subcommand === 'coordinatorReset') {
        await coordinatorReset(args)
    }
}

if (require.main === module) {
    main()
}

export {
    processMessages,
    tally,
    verify,
    processAndTallyWithoutProofs,
    calcBinaryTreeDepthFromMaxLeaves,
    calcQuinTreeDepthFromMaxLeaves,
}
