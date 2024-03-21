class User {
    constructor(
        ws
        , id
        , name
        , family
    ) {
        this.ws = ws;
        this.id = id;
        this.name = name;
        this.family = family;
    }

    toJSON() {
        const copy = { ...this };
        delete copy.ws;
        return copy;
    }
}

module.exports = User;
