// SPDX-License-Identifier: MIT

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.6.12;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];

        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract QuadVoteTallyVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[11] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha1 = Pairing.G1Point(uint256(19598052309948002641672991423456005631037451768516150187044831827364038244764),uint256(9362280103810827234051506103246981042252770717722781162615279274626174631018));
        vk.beta2 = Pairing.G2Point([uint256(10954291843783065294015385598475937412589389165367214748718599541614475224884),uint256(18921708354172586001990805656419056892521426809719809962668369643993634939650)], [uint256(20734946052124447085112848723862541662133962329755418337551020327103827875400),uint256(9262000311269231866554741641715948807295625132646204670277424438235987816787)]);
        vk.gamma2 = Pairing.G2Point([uint256(10338246099006259670346856584022743270671879101830150516409967639004939296601),uint256(7516056346244922125062442161105970318164932884081749471413995035410561709673)], [uint256(9407599694142061052393664435724158244148458414437680087102837439044992157000),uint256(6953303127813954916709723507829790798496735016889433488273163731123085457352)]);
        vk.delta2 = Pairing.G2Point([uint256(17831245032371153068926979738811672978563685876201065579000493814598183958611),uint256(3917011680793836244442562038236916038034889292337499604247400664561688597310)], [uint256(4338166231308451177736741324040404439208642107514044611728190307218644465773),uint256(7758251951014744103023606979106872589918984298074453592790705980156161018440)]);
        vk.IC[0] = Pairing.G1Point(uint256(16235808269060666190898423139882242314896325085959732349758158485662778843710),uint256(21361900979098792053144316372166476092399615446360715904026954083999983889062));
        vk.IC[1] = Pairing.G1Point(uint256(18415232307361560381686039124752991563192251424056460406801044411682269996956),uint256(10248747937335907352667670978268126722915151659174877779020421248664292309067));
        vk.IC[2] = Pairing.G1Point(uint256(15265224628173689331324271667907794843012021720281776409935154677680988786765),uint256(5725579773415320951724081288837982592482247396808765433629178607595802767350));
        vk.IC[3] = Pairing.G1Point(uint256(12594917881655424551101535110519187006976921810138804100160069039395721245319),uint256(11310738393880410073639115400415198985538799785554154408570910926303712763476));
        vk.IC[4] = Pairing.G1Point(uint256(20848598411479330687010903122945049330791536699394435034163995444351128040805),uint256(19870688383088717735272208776846880241292487124657286126452508913033341150275));
        vk.IC[5] = Pairing.G1Point(uint256(14298644969676440982986268976371234291466063735053709587721017780034921841846),uint256(4248480559706389085827835059352269908918634866637028234587367520567569964891));
        vk.IC[6] = Pairing.G1Point(uint256(4205622481518777026709193554794463992053490098299837606872611329750948199985),uint256(9119487494654239656044870237433426223639226540537407761175370835642506211461));
        vk.IC[7] = Pairing.G1Point(uint256(19266360967189489548124345982199557584462754733841464505128086917608949563807),uint256(19816045012309782964664762556179085200111390839564253291586927909310882663813));
        vk.IC[8] = Pairing.G1Point(uint256(12654850808425170799239319266774634162015943800242300088106957561026910120209),uint256(8592275100568627096046036746521502485491248284502509523598191713369598511486));
        vk.IC[9] = Pairing.G1Point(uint256(18659114283314245595535545268150250090682778450348028419321920148877943426205),uint256(18603485683578176011302013403708381372860364304594476702777465048085309057007));
        vk.IC[10] = Pairing.G1Point(uint256(2486094778946392709872531931074619226198893684170780895464081788362591989661),uint256(16192372902886636031402848144527574184604905771497548854872217756742231535697));

    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        //for (uint256 i = 0; i < input.length; i++) {
        for (uint256 i = 0; i < 10; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alpha1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}
