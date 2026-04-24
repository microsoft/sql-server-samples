 package main

    import (
        "fmt"
        "github.com/jinzhu/gorm"
        _ "github.com/jinzhu/gorm/dialects/mssql"
        "log"
    )

    var server = "your_server.database.windows.net"
    var user = "your_user"
    var password = "your_password"
    var database = "your_database"

    // Define a User model struct
    type User struct {
        gorm.Model
        FirstName string
        LastName string
    }

    // Define a Task model struct
    type Task struct {
        gorm.Model
        Title string
        DueDate string
        IsComplete bool
        UserID  uint
    }

    // Read and print all the tasks
    func ReadAllTasks(db *gorm.DB){
        var users []User
        var tasks []Task
        db.Find(&users)

        for _, user := range users{
            db.Model(&user).Related(&tasks)
            fmt.Printf("%s %s's tasks:\n", user.FirstName, user.LastName)
            for _, task := range tasks {
                fmt.Printf("Title: %s\nDueDate: %s\nIsComplete:%t\n\n",
                                task.Title, task.DueDate, task.IsComplete)
            }
        }
    }

    // Update a task based on a user
    func UpdateSomeonesTask(db *gorm.DB, userId int){
        var task Task
        db.Where("user_id = ?", userId).First(&task).Update("Title", "Buy donuts for Luis")
        fmt.Printf("Title: %s\nDueDate: %s\nIsComplete:%t\n\n",
                        task.Title, task.DueDate, task.IsComplete)
    }

    // Delete all the tasks for a user
    func DeleteSomeonesTasks(db *gorm.DB, userId int){
        db.Where("user_id = ?", userId).Delete(&Task{})
        fmt.Printf("Deleted all tasks for user %d", userId)
    }

    func main() {
        connectionString := fmt.Sprintf("server=%s;user id=%s;password=%s;database=%s",
                                            server, user, password, database)
        db, err := gorm.Open("mssql", connectionString)

        if err != nil {
            log.Fatal("Failed to create connection pool. Error: " + err.Error())
        }
        gorm.DefaultCallback.Create().Remove("mssql:set_identity_insert")
        defer db.Close()

        fmt.Println("Migrating models...")
        db.AutoMigrate(&User{})
        db.AutoMigrate(&Task{})

        // Create awesome Users
        fmt.Println("Creating awesome users...")
        db.Create(&User{FirstName: "Andrea", LastName: "Lam"})      //UserID: 1
        db.Create(&User{FirstName: "Meet", LastName: "Bhagdev"})    //UserID: 2
        db.Create(&User{FirstName: "Luis", LastName: "Bosquez"})    //UserID: 3

        // Create appropriate Tasks for each user
        fmt.Println("Creating new appropriate tasks...")
        db.Create(&Task{
            Title: "Do laundry", DueDate: "2021-03-30", IsComplete: false, UserID: 1})
        db.Create(&Task{
            Title: "Mow the lawn", DueDate: "2021-03-30", IsComplete: false, UserID: 2})
        db.Create(&Task{
            Title: "Do more laundry", DueDate: "2021-03-30", IsComplete: false, UserID: 3})
        db.Create(&Task{
            Title: "Watch TV", DueDate: "2021-03-30", IsComplete: false, UserID: 3})

        // Read
        fmt.Println("\nReading all the tasks...")
        ReadAllTasks(db)

        // Update - update Task title to something more appropriate
        fmt.Println("Updating Andrea's task...")
        UpdateSomeonesTask(db, 1)

        // Delete - delete Luis's task
        DeleteSomeonesTasks(db, 3)
    }