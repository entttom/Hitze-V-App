"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isEnvFlagEnabled = isEnvFlagEnabled;
function isEnvFlagEnabled(value) {
    if (!value) {
        return false;
    }
    return ["1", "true", "yes", "on"].includes(value.trim().toLowerCase());
}
