import ballerina/http;



public type User record {|
    readonly string id;
    readonly string email;
    string password;
|};

public final table<User> key(id) users = table [
        {id: "1", email: "test@test.com", password: "Testpass1"},
        {id: "2", email: "mockt@mock.com", password: "Mockpass2"},
        {id: "3", email: "mail@mail.com", password: "Strongpass3"}
    ];

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:4200"],
        allowCredentials: true,
        allowMethods: ["GET", "POST"]
    }
}
service / on  new http:Listener(8080) {
    
    resource function get users() returns User[] {
        return users.toArray();
    }

    resource function get users/[string id]() returns User|InvalidUserIdError {
        User? user = users[id];
        if user is () {
            return {
                body: {
                    errorMessage: string `Invalid User ID: ${id}`
                }
            };
        }
        return user;
    }

    resource function post users(@http:Payload UserEntry userEntry) returns CreatedUserEntry|UserEmailError {
        foreach var user in users {
            if user.email === userEntry.email {
                return {
                    body: {
                        errorMessage: string `User with that email already exist`
                    }
                };
            }
        }
        string id = (users.length() + 1).toString();
        users.add(<User>{id: id, ...userEntry});
        return <CreatedUserEntry>{
            body: {
                responseMessage: string `user registered`
            }
        };
    }

    resource function post users/resetPassword(@http:Payload EmailEntry emailEntry) returns AcceptedResetPassword|UserEmailError {
        foreach var user in users {
            if user.email === emailEntry.email {
                return {
                    body: {
                        responseMessage: string `Email with link to reset password send to: ${emailEntry.email}`
                    }
                };
            }
        }
        return {
            body: {
                errorMessage: string `Email does not exist: ${emailEntry.email}`
            }
        };
    }

    resource function post auth/login(@http:Payload UserEntry userEntry) returns AuthSucces|UnauthorizedError {
        foreach var user in users {
            if user.email == userEntry.email && user.password == userEntry.password {
                return {
                    body: {
                        responseMessage: string `Auth OK`
                    }
                };
            }
        }
        return {
            body: {
                errorMessage: string `Email or password is invalid`
            }
        };
    }

}

public type UserEntry record {|
    string email;
    string password;
|};

public type EmailEntry record {|
    string email;
|};

public type UnauthorizedError record {|
    *http:Unauthorized;
    ErrorMessage body;
|};

public type AcceptedResetPassword record {|
    *http:Accepted;
    ResponseMessage body;
|};

public type CreatedUserEntry record {|
    *http:Created;
    ResponseMessage body;
|};

public type UserEmailError record {|
    *http:BadRequest;
    ErrorMessage body;
|};

public type InvalidUserIdError record {|
    *http:Conflict;
    ErrorMessage body;
|};

public type AuthSucces record {|
    *http:Ok;
    ResponseMessage body;
|};

public type ResponseMessage record {|
    string responseMessage;
|};

public type ErrorMessage record {|
    string errorMessage;
|};
