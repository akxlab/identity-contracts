import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const createFunctionString = 'function create(address _owner, bytes32 pwdHash, bytes memory data)';
const pwd = 'thisisonmyfortestingpurposes';
const pwdBytes = ethers.utils.defaultAbiCoder.encode(['string'],[pwd]);
const hash = ethers.utils.sha256(pwdBytes)
const hash2 = ethers.utils.sha256(hash)
const id1 = '0x01ad131e6986cd3eac9acc148a1062f6de94a2bd0efc2f47d101afb8b6c67cbb';
const id2 = '0x38f1aaaf1cfd9c4cd8b74494f32bfa76875893ce49c8d991e75033c1404b3871';
const username = "NICK4TEST";

describe("Identity", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployIdentityFixture() {


    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Identity = await ethers.getContractFactory("Identity");
    const identity = await Identity.deploy(`https://localhost/api/identity/`);



    return { identity, owner, otherAccount };
  }

  function getInterface(iface:string) {
    const i = new ethers.utils.Interface([iface]);
    return i;
  }

  function decodeTxData(ifaceStr:string, funcName:string, data:any) {
    const iface = getInterface(ifaceStr);
    return iface.decodeFunctionData(funcName, data);
  }

  describe("Deployment", function () {




    it("Should be deployed", async function () {
      const { identity } = await loadFixture(deployIdentityFixture);


      expect(identity.address).to.not.be.undefined;
    });

    it("Should set the right owner", async function () {
      const { identity, owner } = await loadFixture(deployIdentityFixture);

      expect(await identity.owner()).to.equal(owner.address);
    });



    });

  describe("Identity creation", function() {
    it("Should create a new identity and not revert", async function () {

      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);
      const tx = await identity.create(owner.address, hash2, hash, {from:owner.address});
      await tx.wait();
      //console.log(tx.value);

      // @ts-ignore
      //const data = decodeTxData(createFunctionString, 'create', tx.data);
      // console.log(data)

      //const id = await identity.getID(owner.address);
      // console.log(`ID: ${id}`)


      await expect(await tx.wait()).to.not.be.reverted;
    });

    it("Should create 2 different identity and always equal the same if same pwdhash is used", async function () {

      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);
      const tx = await identity.create(owner.address, hash2, hash, {from:owner.address});
      await tx.wait();
      //console.log(tx.value);

      const tx2 = await identity.create(otherAccount.address, hash, hash, {from:owner.address});
      await tx2.wait();

      const id = await identity.getID(owner.address);
      //console.log(`ID: ${id}`)

      const id11 = await identity.getID(otherAccount.address);
      //console.log(`ID: ${id11}`)

      expect(id).to.equal(id1);
      expect(id11).to.equal(id2);
    });

    it("Should not be able to create 2 IDs for the same address", async function () {
      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);
      const tx = await identity.create(owner.address, hash2, hash, {from:owner.address});
      await tx.wait();
      //console.log(tx.value);

      await expect(identity.create(owner.address, hash2, hash, {from: owner.address})).to.be.reverted;
      // await tx2.wait()
    });

    it("Should set username and return the right one", async function () {
      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);
      const unameTx = await identity.setUsername(owner.address, username);
      await unameTx.wait(1);

      const uname = await identity["getUsername(address)"](owner.address);


      expect(uname[0]).to.be.equal(username);


    });
    it("Should return a token uri", async function () {
      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);
      const tx = await identity.create(owner.address, hash2, hash, {from:owner.address});
      await tx.wait();
      const id = await identity.getID(owner.address);
      const uri = await identity.tokenURI(id);
      console.log(uri)

    });
  });

  describe("Authentication", function() {
    it("Should validate and authenticate the account", async function () {
      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);

     const tx = await identity.create(owner.address, hash2, hash, {from: owner.address});
     await tx.wait();

     const ID = await identity.useIdentity(owner.address,hash2);
     expect(ID).to.be.equal(id1);

    });
    it("Should NOT validate and authenticate the account", async function () {
      const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);

      const tx = await identity.create(owner.address, hash, hash, {from: owner.address});
      await tx.wait();

      await expect(identity.useIdentity(owner.address,hash2)).to.be.reverted;

    });
  })

    describe("Events", function () {
      it("Should emit an event on identity creation", async function () {
        const {identity, owner, otherAccount} = await loadFixture(deployIdentityFixture);

        await expect(identity.create(owner.address, hash2, hash, {from: owner.address})).to.emit(identity, "IdentityCreated");

      });
    });
/*
    describe("Transfers", function () {
      it("Should transfer the funds to the owner", async function () {
        const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
          deployOneYearLockFixture
        );

        await time.increaseTo(unlockTime);

        await expect(lock.withdraw()).to.changeEtherBalances(
          [owner, lock],
          [lockedAmount, -lockedAmount]
        );
      });
    });
  });*/
});
