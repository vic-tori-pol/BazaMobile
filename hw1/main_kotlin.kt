import java.util.*

interface Identifiable {
    val id: String
}

class Storage<T : Identifiable> {
    private val items = mutableListOf<T>()
    fun add(item: T) {
        items.add(item)
    }
    
    fun remove(item: T) {
        items.removeIf { it.id == item.id }
    }
    
    fun getAll(): List<T> {
        return items.toList()
    }
    
    fun valueById(id: String): T? {
        return items.find { it.id == id }
    }
}

open class CanvasUnit {
    open fun drawCanvas(): String {
        return "Базовый элемент холста"
    }
}

data class TextNoteModel(
    override val id: String = UUID.randomUUID().toString(),
    var name: String,
    var text: String
) : Identifiable

data class ReminderNoteModel(
    override val id: String = UUID.randomUUID().toString(),
    var text: String,
    var isCompleted: Boolean = false
) : Identifiable

abstract class Note<Data : Identifiable> : CanvasUnit() {
    abstract var data: Data
    abstract val storage: Storage<Data>
    
    fun update(newData: Data) {
        storage.remove(data)
        data = newData
        storage.add(data)
    }
    
    fun willRemove() {
        storage.remove(data)
    }
    
    override fun drawCanvas(): String {
        return "Заметка с данными: $data"
    }
}

class TextNote(
    override var data: TextNoteModel,
    override val storage: Storage<TextNoteModel> = Storage()
) : Note<TextNoteModel>() {
    init {
        storage.add(data)
    }
    
    override fun drawCanvas(): String {
        return """
        Текстовая заметка:
        Название: ${data.name}
        Текст: ${data.text}
        """.trimIndent()
    }
}

class ReminderNote(
    override var data: ReminderNoteModel,
    override val storage: Storage<ReminderNoteModel> = Storage()
) : Note<ReminderNoteModel>() {
    init {
        storage.add(data)
    }
    
    override fun drawCanvas(): String {
        val status = if (data.isCompleted) "Выполнено" else "В ожидании"
        return """
        Напоминание:
        Текст: ${data.text}
        Статус: $status
        """.trimIndent()
    }
}

class Notebook : CanvasUnit() {
    private val notes = mutableListOf<Note<*>>()
    
    fun add(note: Note<*>) {
        notes.add(note)
    }
    
    fun remove(index: Int) {
        if (index in 0 until notes.size) {
            notes[index].willRemove()
            notes.removeAt(index)
        }
    }
    
    fun getAllNotes(): List<Note<*>> {
        return notes.toList()
    }
    
    override fun drawCanvas(): String {
        if (notes.isEmpty()) {
            return "Нет доступных заметок"
        }
        
        val result = StringBuilder("=== Блокнот ===\n")
        notes.forEachIndexed { index, note ->
            result.append("${index + 1}. ${note.drawCanvas()}\n")
        }
        return result.toString()
    }
}

class ConsoleUI {
    fun showMenuList(options: List<String>): Int {
        println("\n=== Меню ===")
        options.forEachIndexed { index, option ->
            println("${index + 1}. $option")
        }
        
        while (true) {
            try {
                val input = readLine()
                val choice = input?.toInt() ?: throw NumberFormatException()
                
                if (choice in 1..options.size) {
                    return choice
                }
            } catch (e: NumberFormatException) {
            }
            println("Пожалуйста, введите корректный номер (1-${options.size}): ")
        }
    }
    
    fun showCanvas(canvas: CanvasUnit) {
        println(canvas.drawCanvas())
    }
    
    fun readString(message: String = "Введите текст: "): String {
        print(message)
        return readLine() ?: ""
    }
    
    fun readInt(message: String = "Введите число: "): Int {
        while (true) {
            try {
                print(message)
                return readLine()?.toInt() ?: throw NumberFormatException()
            } catch (e: NumberFormatException) {
                println("Некорректный ввод. Пожалуйста, введите целое число.")
            }
        }
    }
}

enum class MenuState {
    HOME,
    TEXT_NOTE,
    REMINDER_NOTE,
    TEXT_NEW_NOTE,
    REMINDER_NEW_NOTE
}

class Menu(private val console: ConsoleUI, private val notebook: Notebook) {
    private var currentState: MenuState = MenuState.HOME
    
    fun run() {
        while (true) {
            when (currentState) {
                MenuState.HOME -> showHomeMenu()
                MenuState.TEXT_NOTE, MenuState.REMINDER_NOTE -> showNoteMenu()
                MenuState.TEXT_NEW_NOTE -> createTextNote()
                MenuState.REMINDER_NEW_NOTE -> createReminderNote()
            }
        }
    }
    
    private fun showHomeMenu() {
        console.showCanvas(notebook)
        val options = listOf(
            "Просмотреть все заметки",
            "Редактировать заметку",
            "Добавить новую заметку",
            "Удалить заметку",
            "Выход"
        )
        val choice = console.showMenuList(options)
        
        when (choice) {
            1 -> { }
            2 -> editNote()
            3 -> showAddNoteMenu()
            4 -> removeNote()
            5 -> {
                println("До свидания!")
                System.exit(0)
            }
        }
    }
    
    private fun showAddNoteMenu() {
        val options = listOf("Текстовая заметка", "Напоминание", "Назад")
        val choice = console.showMenuList(options)
        when (choice) {
            1 -> currentState = MenuState.TEXT_NEW_NOTE
            2 -> currentState = MenuState.REMINDER_NEW_NOTE
            3 -> currentState = MenuState.HOME
        }
    }
    
    private fun showNoteMenu() {
        currentState = MenuState.HOME
    }
    
    private fun createTextNote() {
        val name = console.readString("Введите название заметки: ")
        val text = console.readString("Введите текст заметки: ")
        val model = TextNoteModel(name = name, text = text)
        val textNote = TextNote(model)
        notebook.add(textNote)
        currentState = MenuState.HOME
        println("Текстовая заметка успешно создана!")
    }
    
    private fun createReminderNote() {
        val text = console.readString("Введите текст напоминания: ")
        val model = ReminderNoteModel(text = text)
        val reminderNote = ReminderNote(model)
        notebook.add(reminderNote)
        currentState = MenuState.HOME
        println("Напоминание успешно создано!")
    }
    
    private fun editNote() {
        val notes = notebook.getAllNotes()
        if (notes.isEmpty()) {
            println("Нет заметок для редактирования")
            return
        }
        val index = console.readInt("Введите номер заметки для редактирования: ") - 1
        if (index !in 0 until notes.size) {
            println("Неверный номер заметки")
            return
        }
        
        val note = notes[index]
        when (note) {
            is TextNote -> editTextNote(note)
            is ReminderNote -> editReminderNote(note)
            else -> println("Неизвестный тип заметки")
        }
    }
    
    private fun editTextNote(textNote: TextNote) {
        println("Текущая заметка:")
        console.showCanvas(textNote)
        val newName = console.readString("Введите новое название (текущее: ${textNote.data.name}): ")
        val newText = console.readString("Введите новый текст (текущий: ${textNote.data.text}): ")
        val newModel = textNote.data.copy(
            name = if (newName.isNotEmpty()) newName else textNote.data.name,
            text = if (newText.isNotEmpty()) newText else textNote.data.text
        )
        textNote.update(newModel)
        println("Заметка успешно обновлена!")
    }
    
    private fun editReminderNote(reminderNote: ReminderNote) {
        println("Текущее напоминание:")
        console.showCanvas(reminderNote)
        val newText = console.readString("Введите новый текст (текущий: ${reminderNote.data.text}): ")
        val completedChoice = console.readString("Отметить как выполненное? (д/н): ")
        val newModel = reminderNote.data.copy(
            text = if (newText.isNotEmpty()) newText else reminderNote.data.text,
            isCompleted = completedChoice.equals("д", ignoreCase = true)
        )
        reminderNote.update(newModel)
        println("Напоминание успешно обновлено!")
    }
    
    private fun removeNote() {
        val notes = notebook.getAllNotes()
        if (notes.isEmpty()) {
            println("Нет заметок для удаления")
            return
        }
        
        val index = console.readInt("Введите номер заметки для удаления: ") - 1
        if (index !in 0 until notes.size) {
            println("Неверный номер заметки")
            return
        }
        
        notebook.remove(index)
        println("Заметка успешно удалена")
    }
}

class NoteApp {
    fun run() {
        val console = ConsoleUI()
        val notebook = Notebook()
        val menu = Menu(console, notebook)
        println("Добро пожаловать в приложение Заметки!")
        menu.run()
    }
}

fun main() {
    val app = NoteApp()
    app.run()
}
