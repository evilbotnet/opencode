package terminal

import (
	"bytes"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"

	"github.com/creack/pty"
	tea "github.com/charmbracelet/bubbletea/v2"
	"github.com/charmbracelet/lipgloss/v2"
	"github.com/sst/opencode/internal/styles"
	"github.com/sst/opencode/internal/theme"
)

type TerminalComponent interface {
	tea.Model
	tea.ViewModel
	Focused() bool
	Focus() (tea.Model, tea.Cmd)
	Blur()
}

type terminalComponent struct {
	width       int
	height      int
	focused     bool
	cmd         *exec.Cmd
	ptmx        *os.File
	buffer      *bytes.Buffer
	output      []string
	mu          sync.Mutex
	running     bool
	cursorLine  int
	scrollOffset int
}

type TerminalOutputMsg struct {
	data []byte
}

type TerminalExitMsg struct {
	err error
}

func (m *terminalComponent) Init() tea.Cmd {
	return tea.Batch(
		m.startShell(),
		m.readPTY(),
	)
}

func (m *terminalComponent) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width / 2
		m.height = msg.Height - 4
		if m.ptmx != nil {
			pty.Setsize(m.ptmx, &pty.Winsize{
				Rows: uint16(m.height),
				Cols: uint16(m.width),
			})
		}
		return m, nil

	case tea.KeyPressMsg:
		if !m.focused {
			return m, nil
		}

		// Handle keyboard input
		switch msg.String() {
		case "ctrl+c":
			// Send interrupt to shell
			if m.ptmx != nil {
				m.ptmx.Write([]byte{0x03}) // ETX (End of Text)
			}
			return m, nil
		case "enter":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\r"))
			}
			return m, nil
		case "backspace":
			if m.ptmx != nil {
				m.ptmx.Write([]byte{0x7f}) // DEL
			}
			return m, nil
		case "tab":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\t"))
			}
			return m, nil
		case "up":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\033[A"))
			}
			return m, nil
		case "down":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\033[B"))
			}
			return m, nil
		case "left":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\033[D"))
			}
			return m, nil
		case "right":
			if m.ptmx != nil {
				m.ptmx.Write([]byte("\033[C"))
			}
			return m, nil
		default:
			// Send printable characters to PTY
			if msg.Text != "" {
				if m.ptmx != nil {
					m.ptmx.Write([]byte(msg.Text))
				}
			}
		}
		return m, nil

	case TerminalOutputMsg:
		m.mu.Lock()
		defer m.mu.Unlock()

		// Append output to buffer
		m.buffer.Write(msg.data)

		// Parse buffer into lines
		content := m.buffer.String()
		m.output = strings.Split(content, "\n")

		// Auto-scroll to bottom
		if len(m.output) > m.height {
			m.scrollOffset = len(m.output) - m.height
		}

		return m, m.readPTY()

	case TerminalExitMsg:
		m.running = false
		return m, nil
	}

	return m, nil
}

func (m *terminalComponent) View() string {
	t := theme.CurrentTheme()

	borderStyle := lipgloss.ThickBorder()
	borderColor := t.Border()
	if m.focused {
		borderColor = t.Primary()
	}

	// Render terminal output
	var visibleLines []string
	m.mu.Lock()
	totalLines := len(m.output)
	if totalLines > 0 {
		startLine := m.scrollOffset
		endLine := startLine + m.height
		if endLine > totalLines {
			endLine = totalLines
		}
		if startLine < 0 {
			startLine = 0
		}
		if startLine < totalLines {
			visibleLines = m.output[startLine:endLine]
		}
	}
	m.mu.Unlock()

	// Build content
	content := strings.Join(visibleLines, "\n")

	// Ensure we have enough lines to fill the height
	lineCount := strings.Count(content, "\n") + 1
	if lineCount < m.height {
		content += strings.Repeat("\n", m.height-lineCount)
	}

	// Apply styling with proper sizing for borders and padding
	// Account for: border (2 cols) + padding (2 cols) = 4 cols total
	contentWidth := m.width - 4
	if contentWidth < 1 {
		contentWidth = 1
	}

	terminalStyle := styles.NewStyle().
		Width(contentWidth).
		Height(m.height).
		Background(t.Background()).
		Foreground(t.Text()).
		Padding(0, 1).
		BorderStyle(borderStyle).
		BorderForeground(borderColor).
		BorderBackground(t.Background())

	return terminalStyle.Render(content)
}

func (m *terminalComponent) Focused() bool {
	return m.focused
}

func (m *terminalComponent) Focus() (tea.Model, tea.Cmd) {
	m.focused = true
	return m, nil
}

func (m *terminalComponent) Blur() {
	m.focused = false
}

func (m *terminalComponent) startShell() tea.Cmd {
	return func() tea.Msg {
		// Determine shell to use
		shell := os.Getenv("SHELL")
		if shell == "" {
			shell = "/bin/sh"
		}

		// Create command
		m.cmd = exec.Command(shell)
		m.cmd.Env = os.Environ()

		// Start PTY
		var err error
		m.ptmx, err = pty.Start(m.cmd)
		if err != nil {
			return TerminalExitMsg{err: err}
		}

		// Set PTY size
		pty.Setsize(m.ptmx, &pty.Winsize{
			Rows: uint16(m.height),
			Cols: uint16(m.width),
		})

		m.running = true

		// Wait for shell to exit in background
		go func() {
			m.cmd.Wait()
			m.ptmx.Close()
		}()

		return nil
	}
}

func (m *terminalComponent) readPTY() tea.Cmd {
	return func() tea.Msg {
		if m.ptmx == nil {
			return nil
		}

		buf := make([]byte, 1024)
		n, err := m.ptmx.Read(buf)
		if err != nil {
			if err == io.EOF {
				return TerminalExitMsg{err: nil}
			}
			return TerminalExitMsg{err: err}
		}

		return TerminalOutputMsg{data: buf[:n]}
	}
}

func NewTerminalComponent(width, height int) TerminalComponent {
	return &terminalComponent{
		width:       width / 2,
		height:      height - 4,
		focused:     false,
		buffer:      &bytes.Buffer{},
		output:      []string{""},
		running:     false,
		cursorLine:  0,
		scrollOffset: 0,
	}
}
