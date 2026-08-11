class ValidationResult {
  const ValidationResult(this.message, {this.isValid = false});
  final String? message;
  final bool isValid;

  static const valid = ValidationResult(null, isValid: true);
}

abstract class Validator {
  ValidationResult validate(String? value);
}

class NameValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return const ValidationResult('Name is required');
    if (name.length < 2) return const ValidationResult('Name is too short');
    if (name.length > 50) return const ValidationResult('Name is too long');
    if (!RegExp(r"^[a-zA-Z\s']+$").hasMatch(name)) {
      return const ValidationResult('Only letters and spaces allowed');
    }
    return ValidationResult.valid;
  }
}

class MobileValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final mobile = value?.trim() ?? '';
    if (mobile.isEmpty) return const ValidationResult('Mobile number is required');
    if (mobile.length != 10) return const ValidationResult('Must be exactly 10 digits');
    if (!RegExp(r'^[0-9]+$').hasMatch(mobile)) {
      return const ValidationResult('Only digits allowed');
    }
    return ValidationResult.valid;
  }
}

class PinValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final pin = value?.trim() ?? '';
    if (pin.isEmpty) return const ValidationResult('PIN is required');
    if (pin.length != 4) return const ValidationResult('Must be 4 digits');
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      return const ValidationResult('Only digits allowed');
    }
    return ValidationResult.valid;
  }
}

class UsernameValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return const ValidationResult('Username is required');
    if (username.length < 3) return const ValidationResult('Too short (min 3)');
    if (username.length > 15) return const ValidationResult('Too long (max 15)');
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(username)) {
      return const ValidationResult('Only a-z, 0-9, . and _ allowed');
    }
    return ValidationResult.valid;
  }
}

class EmailValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return const ValidationResult('Email is required');
    if (email.length > 100) return const ValidationResult('Email is too long');
    final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
    if (!emailRegex.hasMatch(email)) {
      return const ValidationResult('Invalid email format');
    }
    return ValidationResult.valid;
  }
}

class IdValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return const ValidationResult('ID is required');
    if (id.length < 3) return const ValidationResult('Too short (min 3)');
    if (id.length > 20) return const ValidationResult('Too long (max 20)');
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      return const ValidationResult('Only letters, numbers, - and _ allowed');
    }
    return ValidationResult.valid;
  }
}

class OrganizationNameValidator implements Validator {
  @override
  ValidationResult validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return const ValidationResult('Name is required');
    if (name.length < 3) return const ValidationResult('Too short (min 3)');
    if (name.length > 100) return const ValidationResult('Too long (max 100)');
    return ValidationResult.valid;
  }
}
