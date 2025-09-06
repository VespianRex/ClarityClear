// Mock for lucide-react icons
const React = require('react');

// Create a generic mock component for all lucide icons
const createMockIcon = (name) => {
  const MockIcon = React.forwardRef((props, ref) => {
    return React.createElement('svg', {
      ...props,
      ref,
      'data-testid': `${name}-icon`,
      'aria-label': name,
    });
  });
  MockIcon.displayName = `Mock${name}`;
  return MockIcon;
};

// Export commonly used icons
module.exports = {
  Search: createMockIcon('Search'),
  MapPin: createMockIcon('MapPin'),
  CheckCircle: createMockIcon('CheckCircle'),
  XCircle: createMockIcon('XCircle'),
  AlertCircle: createMockIcon('AlertCircle'),
  Phone: createMockIcon('Phone'),
  Mail: createMockIcon('Mail'),
  Calendar: createMockIcon('Calendar'),
  Clock: createMockIcon('Clock'),
  User: createMockIcon('User'),
  Home: createMockIcon('Home'),
  Truck: createMockIcon('Truck'),
  Star: createMockIcon('Star'),
  Menu: createMockIcon('Menu'),
  X: createMockIcon('X'),
  ChevronDown: createMockIcon('ChevronDown'),
  ChevronUp: createMockIcon('ChevronUp'),
  ChevronLeft: createMockIcon('ChevronLeft'),
  ChevronRight: createMockIcon('ChevronRight'),
  ArrowRight: createMockIcon('ArrowRight'),
  ArrowLeft: createMockIcon('ArrowLeft'),
  Plus: createMockIcon('Plus'),
  Minus: createMockIcon('Minus'),
  Edit: createMockIcon('Edit'),
  Trash: createMockIcon('Trash'),
  Save: createMockIcon('Save'),
  Download: createMockIcon('Download'),
  Upload: createMockIcon('Upload'),
  Eye: createMockIcon('Eye'),
  EyeOff: createMockIcon('EyeOff'),
  Lock: createMockIcon('Lock'),
  Unlock: createMockIcon('Unlock'),
  Settings: createMockIcon('Settings'),
  Info: createMockIcon('Info'),
  HelpCircle: createMockIcon('HelpCircle'),
  ExternalLink: createMockIcon('ExternalLink'),
  Copy: createMockIcon('Copy'),
  Check: createMockIcon('Check'),
  // Add any other icons that might be used in the project
};