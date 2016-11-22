module.exports= {
    ME: /^me$/i
    MULTILINE: /^multi$/i

    KEFU: /^kf$/i
    KEFU_CHATID: /^\d{4}$/
    KEFU_ONLINE: /^ol$/
    KEFU_CREATE: /^c\s+(\w+)@(\w+)$/i
    KEFU_INVITE: /^i\s+(\w+)@(\w+)$/i
    KEFU_DELETE: /^x\s+(\d+)$/i

    MASS_SEND: /^@(\w+)\s*(.*)$/i

    CREATE_TAG: /^ct\s+(.*)/i
    TAG_LIST: /^tl$/i
    UPDATE_TAG: /^ut\s+(\d+)@(.*)/i
    DELETE_TAG: /^dt\s+(\d+)$/i
    USER_LIST: /^ul$/i
    TAGFAN_LIST: /^tfan\s+(\d+)$/i
    REMOVE_USER_TAG: /^rut\s+(\w+)@(\d+)$/i
    ADD_USER_TAG: /^aut\s+(\w+)@(\d+)$/i
    USER_TAGLIST: /^utl\s+(\w+)$/i

    LOCATE: /^lc$/i

    REDIS_IN: /^rein\s+(\d{6})@(\w+)$/i
    REDIS_OUT: /^reout\s+(\w+)$/i
    TEMPLATE: /^tp$/i
    REMARK: /^remark\s+(\w+)$/i
    ACCEPTLINK: /^abs$/i
    DELETELINK: /^xlink$/i

    MENU: /^menu\s+(\w+)$/i
    DELETE_MENU: /^md$/i

    ADD_AREA: /^addc\s+(\d{6})@(.+)$/i
    IN_XLSX_AREA: /^ixls$/i
}