package com.aicompanion.common.response;

import lombok.Data;
import java.io.Serializable;

@Data
public class Result<T> implements Serializable {

    private int code;
    private String message;
    private T data;

    /** 成功（无数据） */
    public static <T> Result<T> success() {
        return success(null);
    }

    /** 成功（有数据） */
    public static <T> Result<T> success(T data) {
        Result<T> r = new Result<>();
        r.setCode(200);
        r.setMessage("操作成功");
        r.setData(data);
        return r;
    }

    /** 成功（自定义消息 + 数据） */
    public static <T> Result<T> success(String message, T data) {
        Result<T> r = new Result<>();
        r.setCode(200);
        r.setMessage(message);
        r.setData(data);
        return r;
    }

    /** 失败（默认 500） */
    public static <T> Result<T> error(String message) {
        return error(500, message);
    }

    /** 失败（自定义状态码） */
    public static <T> Result<T> error(int code, String message) {
        Result<T> r = new Result<>();
        r.setCode(code);
        r.setMessage(message);
        return r;
    }

    /** 参数错误（400） */
    public static <T> Result<T> badRequest(String message) {
        return error(400, message);
    }
}