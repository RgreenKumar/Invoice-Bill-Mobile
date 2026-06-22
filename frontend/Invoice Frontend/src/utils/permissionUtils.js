import MODULES from "./modules";
import { secureGet } from "./secureStorage";

export const getPermission = (moduleName, action) => {
    const role = sessionStorage.getItem("role");
    if (role === "ADMIN" || role === "SYSADMIN") return true;
    const permissions = secureGet("permissions") || {};
    return permissions[moduleName]?.[action] === true;
};