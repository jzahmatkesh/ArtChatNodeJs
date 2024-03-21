const express = require('express');
const router = express.Router();
const userService = require('../services/users');

router.get('/', async function (req, res, next) {
    try {
        res.json(await userService.getData(req.headers));
    } catch (err) {
        console.error(`Error on get user list`, err.message);
        next(err);
    }
});
router.post('/authenticate', async function (req, res, next) {
    try {
        if (req.body.email && req.body.password)
            res.json(await userService.authenticate(req.headers, req.body));
        else
            throw new Error("data is not correct");
    } catch (err) {
        console.error(`Error while authenticating`, err.message);
        next(err);
    }
});
router.post('/verifybytoken', async function (req, res, next) {
    try {
        if (req.body.token)
            res.json(await userService.verifybytoken(req.headers, req.body));
        else
            throw new Error("data is not correct");
    } catch (err) {
        console.error(`Error while authenticating`, err.message);
        next(err);
    }
});
router.post('/verifybygoogle', async function (req, res, next) {
    try {
        if (req.body.idtoken)
            res.json(await userService.googleVerify(req.headers, req.body));
        else
            throw new Error("data is not correct");
    } catch (err) {
        next(err);
    }
});
router.put('/', async function (req, res, next) {
    try {
        res.json(await userService.register(req.headers, req.body));
    } catch (err) {
        console.error(`Error while authenticating`, err.message);
        next(err);
    }
});
router.get('/friends', async function (req, res, next) {
    try {
        res.json(await userService.getFriends(req.headers));
    } catch (err) {
        console.error(`Error on get user list`, err.message);
        next(err);
    }
});
router.get('/findfriend/:family', async function (req, res, next) {
    try {
        res.json(await userService.findFriends(req.headers, req.params.family));
    } catch (err) {
        console.error(`Error on find friend`, err.message);
        next(err);
    }
});
router.get('/avatars', async function (req, res, next) {
    try {
        res.json(await userService.getAvatars(req.headers, req.params.family));
    } catch (err) {
        console.error(`Error on load avatars`, err.message);
        next(err);
    }
});


module.exports = router;