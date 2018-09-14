import * as React from "react"

const About = (props: any) => (
  <section className="section">
    <h1>About</h1>
    <p>
      <strong>
        It's Just a Tamagotchi Game to show off EOS blockchain potential! You as  an early adopter, will have a chance to carry a very old Monster while the game is in progress, getting cool functionalities and public traction :D
      </strong>
    </p>
    <p>
      This project is a mini-game experiment for EOS Blockchain, still in progress. It's open sourced and all of us can tweak the contract, architecture and design of tables to see what works the best in terms of performance and good practices for EOS.
    </p>
    <p>
      To keep your pet alive you must feed him, play with him, take him to the bed and wash him!
    </p>
    <p>
      Only the feeding and sleeping/awake feature is done for now... There's a lot of interesting stuff that we can do here to improve the project like experience points (+ age and evolutions), inventory of items, multiplayer options, breeding, ownership transferring and tokenization.
    </p>
    <p>
      We would love to have more and more developers to get in touch in GitHub repository, open issues, open discussions and so on, about what would be the best way to design the architecture and implement the contracts, how things should work in blockchain, how we should integrate Scatter, other wallets and provide top-security, what we should avoid, what's the best practice in terms of coding and everything else.
    </p>
    <p>
      We love EOS Community and we think that we can build a better world together!
    </p>
    <p>
      Check our
      {" "}
      <a href="https://github.com/MonsterEOS/monstereos" target="_blank">
        GitHub repo
      </a>
      {" "}
      to see all our code and proper credits on arts, images, etc. You can also build your EOS game! :)
    </p>

    <h2>Partnerships</h2>
    <p>
      Large Seafaring Mammal:
      {" "}
      <a href="https://largeseafaringmammal.com/products/monstereos-x-lsm" target="_blank">
      Buy your shirt here!
      </a>
    </p>

    <h2>Disclaimer</h2>
    <p>
      This project remains purely experimental software and is not to be considered in any way production fit nor has any guarantee of any kind. Use at your own risk.
    </p>
    <p>
      Any transferred tokens sent to account name 'monstereosio' will not return any entitlement of any asset, investment digital or physical including the sent asset itself. Any proceeds received from any user transfers are of the sole control and discretion of the receiver.
    </p>
  </section>
)

export default About