import CryptoJS from "crypto-js";

const SECRET_KEY = process.env.REACT_APP_SECRET_KEY;

export const secureSet = (key, value) => {
    const encrypted = CryptoJS.AES.encrypt(
        JSON.stringify(value),
        SECRET_KEY
    ).toString();
    sessionStorage.setItem(key, encrypted);
};

export const secureGet = (key) => {
    const encrypted = sessionStorage.getItem(key);
    if (!encrypted) return null;
    try {
        const decrypted = CryptoJS.AES.decrypt(encrypted, SECRET_KEY);
        return JSON.parse(decrypted.toString(CryptoJS.enc.Utf8));
    } catch (err) {
        return null;
    }
};