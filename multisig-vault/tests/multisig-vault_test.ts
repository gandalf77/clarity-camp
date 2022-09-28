
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

const contractName = 'multisig-vault';

const defaultStxVaultAmount = 5000;
const defaultMembers = ['deployer', 'wallet_1', 'wallet_2', 'wallet_3', 'wallet_4'];
const defaultVotesRequired = defaultMembers.length - 1;

type InitContractOptions = {
    chain: Chain,
    accounts: Map<string, Account>,
    members?: Array<string>,
    votesRequired?: number,
    stxVaultAmount?: number
}

function initContract({ chain, accounts, members=defaultMembers, 
    votesRequired=defaultVotesRequired, stxVaultAmount=defaultStxVaultAmount }: InitContractOptions) {
        const deployer = accounts.get('deployer')!;
        const contractPrincipal = `${deployer.address}.${contractName}`;
        const memberAccounts = members.map(name => accounts.get(name)!);
        const nonMemberAccounts = Array.from(accounts.keys()).filter(key => 
            !members.includes(key)).map(name => accounts.get(name)!);
        const startBlock = chain.mineBlock([
            Tx.contractCall(contractName, 'start', 
                [types.list(memberAccounts.map(account => types.principal(account.address))), 
                types.uint(votesRequired)], deployer.address),
            Tx.contractCall(contractName, 'deposit',
                [types.uint(stxVaultAmount)], deployer.address),
        ]);
        return { deployer, contractPrincipal, memberAccounts, nonMemberAccounts, startBlock };
}

Clarinet.test({
    name: "Allows the contract owner to initialise the vault",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const memberB = accounts.get('wallet_1')!;
        const votesRequired = 1;
        const memberList =
            types.list([types.principal(deployer.address),
            types.principal(memberB.address)])
        const block = chain.mineBlock([
            Tx.contractCall(contractName, 'start', [memberList, types.uint(votesRequired)], deployer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
    }
})

Clarinet.test({
    name: "Does not allow anyone else to initialise the vault",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const memberB = accounts.get('wallet_1')!;
        const votesRequired = 1;
        const memberList = types.list([types.principal(deployer.address), types.principal(memberB.address)]);
        const block = chain.mineBlock([
            Tx.contractCall(contractName, 'start', [memberList, types.uint(votesRequired)], memberB.address)
        ]);
        block.receipts[0].result.expectErr().expectUint(100);
    }
})

Clarinet.test({
    name: "Cannot start the vault more than once",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const memberB = accounts.get('wallet_1')!;
        const votesRequired = 1;
        const memberList = types.list([types.principal(deployer.address), types.principal(memberB.address)]);
        const block = chain.mineBlock([
            Tx.contractCall(contractName, 'start', [memberList, types.uint(votesRequired)], deployer.address),
            Tx.contractCall(contractName, 'start', [memberList, types.uint(votesRequired)], deployer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(101);
    }
});

Clarinet.test({
    name: "Cannot require more votes than members",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const { startBlock } = initContract({ chain, accounts, votesRequired: defaultMembers.length + 1 });
        startBlock.receipts[0].result.expectErr().expectUint(102);
    }
});