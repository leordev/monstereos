import * as React from "react"
import PageHero from "../shared/PageHero"

const HomeScreen = (props: any) => (
  <PageHero>
    <div className="columns">
      <div className="column">
        <figure className="image">
          <img alt="Tamagotchi Monsters" src="/images/ui/logo-monster.png" />
        </figure>
      </div>
      <div className="column">
        <h1 className="title logo">
          A Monster Tamagotchi and Battle game for EOS blockchain! :)
        </h1>
      </div>
    </div>
  </PageHero>
)

export default HomeScreen