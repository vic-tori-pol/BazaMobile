import Foundation

protocol Identifiable {
    var id: String { get }
}

class Storage<T: Identifiable> {
    private var items: [T] = []
    
    func add(_ item: T) {
        items.append(item)
    }
    
    func remove(_ item: T) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
    
    func getAll() -> [T] {
        return items
    }
    
    func value(by id: String) -> T? {
        return items.first { $0.id == id }
    }
}

class CanvasUnit {
    func drawCanvas() -> String {
        return "Базовый элемент холста"
    }
}

protocol NoteProtocol: AnyObject {
    var noteId: String { get }
    func drawCanvas() -> String
    func updateData(_ data: Any)
    func willRemove()
}

struct TextNoteModel: Identifiable {
    let id: String
    var name: String
    var text: String
    
    init(name: String, text: String) {
        self.id = UUID().uuidString
        self.name = name
        self.text = text
    }
}

struct ReminderNoteModel: Identifiable {
    let id: String
    var text: String
    var isCompleted: Bool
    
    init(text: String, isCompleted: Bool = false) {
        self.id = UUID().uuidString
        self.text = text
        self.isCompleted = isCompleted
    }
}

class BaseNote: CanvasUnit, NoteProtocol {
    var noteId: String {
        return "Базовая заметка"
    }
    
    func updateData(_ data: Any) {
    }
    
    func willRemove() {
    }
}

class Note<Data: Identifiable>: BaseNote {
    var data: Data {
        didSet {
            storage.remove(oldValue)
            storage.add(data)
        }
    }
    private var storage: Storage<Data>
    
    override var noteId: String {
        return data.id
    }
    
    init(data: Data, storage: Storage<Data>) {
        self.data = data
        self.storage = storage
        super.init()
        storage.add(data)
    }
    
    override func updateData(_ newData: Any) {
        if let typedData = newData as? Data {
            data = typedData
        }
    }
    
    override func willRemove() {
        storage.remove(data)
    }
    
    override func drawCanvas() -> String {
        return "Заметка с данными: \(data)"
    }
}

class TextNote: Note<TextNoteModel> {
    override func drawCanvas() -> String {
        return """
        Текстовая заметка:
        Название: \(data.name)
        Текст: \(data.text)
        """
    }
}

class ReminderNote: Note<ReminderNoteModel> {
    override func drawCanvas() -> String {
        let status = data.isCompleted ? "Выполнено" : "В ожидании"
        return """
        Напоминание:
        Текст: \(data.text)
        Статус: \(status)
        """
    }
}

class Notebook: CanvasUnit {
    private var notes: [NoteProtocol] = []
    
    func add(_ note: NoteProtocol) {
        notes.append(note)
    }
    
    func remove(at index: Int) {
        guard index >= 0 && index < notes.count else { return }
        notes[index].willRemove()
        notes.remove(at: index)
    }
    
    func getAllNotes() -> [NoteProtocol] {
        return notes
    }
    
    override func drawCanvas() -> String {
        if notes.isEmpty {
            return "Нет доступных заметок"
        }
        
        var result = "=== Блокнот ===\n"
        for (index, note) in notes.enumerated() {
            result += "\(index + 1). \(note.drawCanvas())\n"
        }
        return result
    }
}

class ConsoleUI {
    func showMenuList(_ options: [String]) -> Int {
        print("\n=== Меню ===")
        for (index, option) in options.enumerated() {
            print("\(index + 1). \(option)")
        }
        
        while true {
            if let input = readLine(), let choice = Int(input) {
                if choice >= 1 && choice <= options.count {
                    return choice
                }
            }
            print("Пожалуйста, введите корректный номер (1-\(options.count)): ")
        }
    }
    
    func showCanvas(_ canvas: CanvasUnit) {
        print(canvas.drawCanvas())
    }
    
    func showNoteCanvas(_ note: NoteProtocol) {
        if let canvasNote = note as? CanvasUnit {
            print(canvasNote.drawCanvas())
        } else {
            print(note.drawCanvas())
        }
    }
    
    func readString(_ message: String = "Введите текст: ") -> String {
        print(message, terminator: "")
        return readLine() ?? ""
    }
    
    func readInt(_ message: String = "Введите число: ") -> Int {
        while true {
            print(message, terminator: "")
            if let input = readLine(), let value = Int(input) {
                return value
            }
            print("Некорректный ввод. Пожалуйста, введите целое число.")
        }
    }
}

enum MenuState {
    case home
    case textNote
    case reminderNote
    case textNewNote
    case reminderNewNote
}

class Menu {
    private let console: ConsoleUI
    private var currentState: MenuState = .home
    private let notebook: Notebook
    init(console: ConsoleUI, notebook: Notebook) {
        self.console = console
        self.notebook = notebook
    }
    
    func run() {
        while true {
            switch currentState {
            case .home:
                showHomeMenu()
            case .textNote, .reminderNote:
                showNoteMenu()
            case .textNewNote:
                createTextNote()
            case .reminderNewNote:
                createReminderNote()
            }
        }
    }
    
    private func showHomeMenu() {
        console.showCanvas(notebook)
        let options = [
            "Просмотреть все заметки",
            "Редактировать заметку",
            "Добавить новую заметку",
            "Удалить заметку",
            "Выход"
        ]
        let choice = console.showMenuList(options)
        
        switch choice {
        case 1:
            break
        case 2:
            editNote()
        case 3:
            showAddNoteMenu()
        case 4:
            removeNote()
        case 5:
            print("До свидания!")
            exit(0)
        default:
            break
        }
    }
    
    private func showAddNoteMenu() {
        let options = ["Текстовая заметка", "Напоминание", "Назад"]
        let choice = console.showMenuList(options)
        switch choice {
        case 1:
            currentState = .textNewNote
        case 2:
            currentState = .reminderNewNote
        case 3:
            currentState = .home
        default:
            break
        }
    }
    
    private func showNoteMenu() {
        currentState = .home
    }
    
    private func createTextNote() {
        let name = console.readString("Введите название заметки: ")
        let text = console.readString("Введите текст заметки: ")
        let model = TextNoteModel(name: name, text: text)
        let storage = Storage<TextNoteModel>()
        let textNote = TextNote(data: model, storage: storage)
        notebook.add(textNote)
        currentState = .home
        print("Текстовая заметка успешно создана!")
    }
    
    private func createReminderNote() {
        let text = console.readString("Введите текст напоминания: ")
        let model = ReminderNoteModel(text: text)
        let storage = Storage<ReminderNoteModel>()
        let reminderNote = ReminderNote(data: model, storage: storage)
        notebook.add(reminderNote)
        currentState = .home
        print("Напоминание успешно создано!")
    }
    
    private func editNote() {
        let notes = notebook.getAllNotes()
        if notes.isEmpty {
            print("Нет заметок для редактирования")
            return
        }
        let index = console.readInt("Введите номер заметки для редактирования: ") - 1
        guard index >= 0 && index < notes.count else {
            print("Неверный номер заметки")
            return
        }
        let note = notes[index]
        if let textNote = note as? TextNote {
            editTextNote(textNote)
        } else if let reminderNote = note as? ReminderNote {
            editReminderNote(reminderNote)
        } else {
            print("Неизвестный тип заметки")
        }
    }
    
    private func editTextNote(_ textNote: TextNote) {
        print("Текущая заметка:")
        console.showNoteCanvas(textNote)
        let newName = console.readString("Введите новое название (текущее: \(textNote.data.name)): ")
        let newText = console.readString("Введите новый текст (текущий: \(textNote.data.text)): ")
        let newModel = TextNoteModel(
            name: newName.isEmpty ? textNote.data.name : newName,
            text: newText.isEmpty ? textNote.data.text : newText
        )
        textNote.updateData(newModel)
        print("Заметка успешно обновлена!")
    }
    
    private func editReminderNote(_ reminderNote: ReminderNote) {
        print("Текущее напоминание:")
        console.showNoteCanvas(reminderNote)
        let newText = console.readString("Введите новый текст (текущий: \(reminderNote.data.text)): ")
        let completedChoice = console.readString("Отметить как выполненное? (д/н): ")
        let newModel = ReminderNoteModel(
            text: newText.isEmpty ? reminderNote.data.text : newText,
            isCompleted: completedChoice.lowercased() == "д"
        )
        reminderNote.updateData(newModel)
        print("Напоминание успешно обновлено!")
    }
    
    private func removeNote() {
        let notes = notebook.getAllNotes()
        if notes.isEmpty {
            print("Нет заметок для удаления")
            return
        }
        let index = console.readInt("Введите номер заметки для удаления: ") - 1
        guard index >= 0 && index < notes.count else {
            print("Неверный номер заметки")
            return
        }
        notebook.remove(at: index)
        print("Заметка успешно удалена")
    }
}

class NoteApp {
    func run() {
        let console = ConsoleUI()
        let notebook = Notebook()
        let menu = Menu(console: console, notebook: notebook)
        print("Добро пожаловать в приложение Заметки!")
        menu.run()
    }
}

let app = NoteApp()
app.run()
